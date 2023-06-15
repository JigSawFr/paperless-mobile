import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/core/config/hive/hive_extensions.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/database/tables/local_user_settings.dart';
import 'package:paperless_mobile/core/database/tables/user_credentials.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';

part 'authentication_cubit.freezed.dart';
part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final LocalAuthenticationService _localAuthService;
  final PaperlessApiFactory _apiFactory;
  final SessionManager _sessionManager;

  AuthenticationCubit(
    this._localAuthService,
    this._apiFactory,
    this._sessionManager,
  ) : super(const AuthenticationState.unauthenticated());

  Future<void> login({
    required LoginFormCredentials credentials,
    required String serverUrl,
    ClientCertificate? clientCertificate,
  }) async {
    assert(credentials.username != null && credentials.password != null);
    final localUserId = "${credentials.username}@$serverUrl";
    _debugPrintMessage(
      "login",
      "Trying to login $localUserId...",
    );
    await _addUser(
      localUserId,
      serverUrl,
      credentials,
      clientCertificate,
      _sessionManager,
    );

    final apiVersion = await _getApiVersion(_sessionManager.client);

    // Mark logged in user as currently active user.
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    globalSettings.currentLoggedInUser = localUserId;
    await globalSettings.save();

    emit(
      AuthenticationState.authenticated(
        apiVersion: apiVersion,
        localUserId: localUserId,
      ),
    );
    _debugPrintMessage(
      "login",
      "User successfully logged in.",
    );
  }

  /// Switches to another account if it exists.
  Future<void> switchAccount(String localUserId) async {
    emit(const AuthenticationState.switchingAccounts());
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    if (globalSettings.currentLoggedInUser == localUserId) {
      return;
    }
    final userAccountBox =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);

    if (!userAccountBox.containsKey(localUserId)) {
      debugPrint("User $localUserId not yet registered.");
      return;
    }

    final account = userAccountBox.get(localUserId)!;

    if (account.settings.isBiometricAuthenticationEnabled) {
      final authenticated = await _localAuthService
          .authenticateLocalUser("Authenticate to switch your account.");
      if (!authenticated) {
        debugPrint("User not authenticated.");
        return;
      }
    }
    await withEncryptedBox<UserCredentials, void>(
        HiveBoxes.localUserCredentials, (credentialsBox) async {
      if (!credentialsBox.containsKey(localUserId)) {
        await credentialsBox.close();
        debugPrint("Invalid authentication for $localUserId");
        return;
      }
      final credentials = credentialsBox.get(localUserId);
      await _resetExternalState();

      _sessionManager.updateSettings(
        authToken: credentials!.token,
        clientCertificate: credentials.clientCertificate,
        baseUrl: account.serverUrl,
      );

      globalSettings.currentLoggedInUser = localUserId;
      await globalSettings.save();

      final apiVersion = await _getApiVersion(_sessionManager.client);

      await _updateRemoteUser(
        _sessionManager,
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount)
            .get(localUserId)!,
        apiVersion,
      );

      emit(AuthenticationState.authenticated(
        localUserId: localUserId,
        apiVersion: apiVersion,
      ));
    });
  }

  Future<String> addAccount({
    required LoginFormCredentials credentials,
    required String serverUrl,
    ClientCertificate? clientCertificate,
    required bool enableBiometricAuthentication,
  }) async {
    assert(credentials.password != null && credentials.username != null);
    final localUserId = "${credentials.username}@$serverUrl";
    final sessionManager = SessionManager();
    await _addUser(
      localUserId,
      serverUrl,
      credentials,
      clientCertificate,
      sessionManager,
    );

    return localUserId;
  }

  Future<void> removeAccount(String userId) async {
    final userAccountBox =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);
    final userAppStateBox =
        Hive.box<LocalUserAppState>(HiveBoxes.localUserAppState);

    await userAccountBox.delete(userId);
    await userAppStateBox.delete(userId);
    await withEncryptedBox<UserCredentials, void>(
        HiveBoxes.localUserCredentials, (box) {
      box.delete(userId);
    });
  }

  ///
  /// Performs a conditional hydration based on the local authentication success.
  ///
  Future<void> restoreSessionState() async {
    _debugPrintMessage(
      "restoreSessionState",
      "Trying to restore previous session...",
    );
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    final localUserId = globalSettings.currentLoggedInUser;
    if (localUserId == null) {
      _debugPrintMessage(
        "restoreSessionState",
        "There is nothing to restore.",
      );
      // If there is nothing to restore, we can quit here.
      return;
    }
    final localUserAccountBox =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);
    final localUserAccount = localUserAccountBox.get(localUserId)!;
    _debugPrintMessage(
      "restoreSessionState",
      "Checking if biometric authentication is required...",
    );
    if (localUserAccount.settings.isBiometricAuthenticationEnabled) {
      _debugPrintMessage(
        "restoreSessionState",
        "Biometric authentication required, waiting for user to authenticate...",
      );
      final localAuthSuccess = await _localAuthService
          .authenticateLocalUser("Authenticate to log back in"); //TODO: INTL
      if (!localAuthSuccess) {
        emit(const AuthenticationState.requriresLocalAuthentication());
        _debugPrintMessage(
          "restoreSessionState",
          "User could not be authenticated.",
        );
        return;
      }
      _debugPrintMessage(
        "restoreSessionState",
        "User successfully autheticated.",
      );
    } else {
      _debugPrintMessage(
        "restoreSessionState",
        "Biometric authentication not configured, skipping.",
      );
    }
    _debugPrintMessage(
      "restoreSessionState",
      "Trying to retrieve authentication credentials...",
    );
    final authentication =
        await withEncryptedBox<UserCredentials, UserCredentials>(
            HiveBoxes.localUserCredentials, (box) {
      return box.get(globalSettings.currentLoggedInUser!);
    });

    if (authentication == null) {
      _debugPrintMessage(
        "restoreSessionState",
        "Could not retrieve existing authentication credentials.",
      );
      throw Exception(
        "User should be authenticated but no authentication information was found.",
      ); //TODO: INTL
    }
    _debugPrintMessage(
      "restoreSessionState",
      "Authentication credentials successfully retrieved.",
    );
    _debugPrintMessage(
      "restoreSessionState",
      "Updating current session state...",
    );
    _sessionManager.updateSettings(
      clientCertificate: authentication.clientCertificate,
      authToken: authentication.token,
      baseUrl: localUserAccount.serverUrl,
    );
    _debugPrintMessage(
      "restoreSessionState",
      "Current session state successfully updated.",
    );

    final apiVersion = await _getApiVersion(_sessionManager.client);
    await _updateRemoteUser(
      _sessionManager,
      localUserAccount,
      apiVersion,
    );
    emit(
      AuthenticationState.authenticated(
        apiVersion: apiVersion,
        localUserId: localUserId,
      ),
    );
    _debugPrintMessage(
      "restoreSessionState",
      "Session was successfully restored.",
    );
  }

  Future<void> logout() async {
    _debugPrintMessage(
      "logout",
      "Trying to log out current user...",
    );
    await _resetExternalState();
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    globalSettings.currentLoggedInUser = null;
    await globalSettings.save();

    emit(const AuthenticationState.unauthenticated());
    _debugPrintMessage(
      "logout",
      "User successfully logged out.",
    );
  }

  Future<void> _resetExternalState() async {
    _debugPrintMessage(
      "_resetExternalState",
      "Resetting session manager and clearing storage...",
    );
    _sessionManager.resetSettings();
    await HydratedBloc.storage.clear();
    _debugPrintMessage(
      "_resetExternalState",
      "Session manager successfully reset and storage cleared.",
    );
  }

  Future<int> _addUser(
    String localUserId,
    String serverUrl,
    LoginFormCredentials credentials,
    ClientCertificate? clientCert,
    SessionManager sessionManager,
  ) async {
    assert(credentials.username != null && credentials.password != null);
    _debugPrintMessage("_addUser", "Adding new user $localUserId...");

    sessionManager.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCert,
    );

    final authApi = _apiFactory.createAuthenticationApi(sessionManager.client);

    _debugPrintMessage(
      "_addUser",
      "Trying to login user ${credentials.username} on $serverUrl...",
    );

    final token = await authApi.login(
      username: credentials.username!,
      password: credentials.password!,
    );

    _debugPrintMessage(
      "_addUser",
      "Successfully acquired token.",
    );

    sessionManager.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCert,
      authToken: token,
    );

    final userAccountBox =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);
    final userStateBox =
        Hive.box<LocalUserAppState>(HiveBoxes.localUserAppState);

    if (userAccountBox.containsKey(localUserId)) {
      _debugPrintMessage(
        "_addUser",
        "An error occurred! The user $localUserId already exists.",
      );
      throw Exception("User already exists!");
    }
    final apiVersion = await _getApiVersion(sessionManager.client);
    _debugPrintMessage(
      "_addUser",
      "Trying to fetch user object for $localUserId...",
    );
    late UserModel serverUser;
    try {
      serverUser = await _apiFactory
          .createUserApi(
            sessionManager.client,
            apiVersion: apiVersion,
          )
          .findCurrentUser();
    } on DioError catch (error, stackTrace) {
      _debugPrintMessage(
        "_addUser",
        "An error occurred: ${error.message}",
        stackTrace: stackTrace,
      );
      rethrow;
    }
    _debugPrintMessage(
      "_addUser",
      "User object successfully fetched.",
    );
    _debugPrintMessage(
      "_addUser",
      "Persisting local user account...",
    );
    // Create user account
    await userAccountBox.put(
      localUserId,
      LocalUserAccount(
        id: localUserId,
        settings: LocalUserSettings(),
        serverUrl: serverUrl,
        paperlessUser: serverUser,
      ),
    );
    _debugPrintMessage(
      "_addUser",
      "Local user account successfully persisted.",
    );
    _debugPrintMessage(
      "_addUser",
      "Persisting user state...",
    );
    // Create user state
    await userStateBox.put(
      localUserId,
      LocalUserAppState(userId: localUserId),
    );
    _debugPrintMessage(
      "_addUser",
      "User state successfully persisted.",
    );
    // Save credentials in encrypted box
    await withEncryptedBox(HiveBoxes.localUserCredentials, (box) async {
      _debugPrintMessage(
        "_addUser",
        "Saving user credentials inside encrypted storage...",
      );
      await box.put(
        localUserId,
        UserCredentials(
          token: token,
          clientCertificate: clientCert,
        ),
      );
      _debugPrintMessage(
        "_addUser",
        "User credentials successfully saved.",
      );
    });
    final hostsBox = Hive.box<String>(HiveBoxes.hosts);
    if (!hostsBox.values.contains(serverUrl)) {
      await hostsBox.add(serverUrl);
    }

    return serverUser.id;
  }

  Future<int> _getApiVersion(Dio dio) async {
    _debugPrintMessage(
      "_getApiVersion",
      "Trying to fetch API version...",
    );
    final response = await dio.get("/api/");
    final apiVersion =
        int.parse(response.headers.value('x-api-version') ?? "3");
    _debugPrintMessage(
      "_getApiVersion",
      "API version ($apiVersion) successfully retrieved.",
    );
    return apiVersion;
  }

  /// Fetches possibly updated (permissions, name, updated server version and thus new user model, ...) remote user data.
  Future<void> _updateRemoteUser(
    SessionManager sessionManager,
    LocalUserAccount localUserAccount,
    int apiVersion,
  ) async {
    _debugPrintMessage(
      "_updateRemoteUser",
      "Updating paperless user object...",
    );
    final updatedPaperlessUser = await _apiFactory
        .createUserApi(
          sessionManager.client,
          apiVersion: apiVersion,
        )
        .findCurrentUser();

    localUserAccount.paperlessUser = updatedPaperlessUser;
    await localUserAccount.save();
    _debugPrintMessage(
      "_updateRemoteUser",
      "Paperless user object successfully updated.",
    );
  }

  void _debugPrintMessage(
    String methodName,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    debugPrint("AuthenticationCubit#$methodName: $message");
    if (error != null) {
      debugPrint(error.toString());
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
