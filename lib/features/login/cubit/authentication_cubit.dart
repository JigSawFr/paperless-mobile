import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
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
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    final localUserId = globalSettings.currentLoggedInUser;
    if (localUserId == null) {
      // If there is nothing to restore, we can quit here.
      return;
    }
    final localUserAccountBox =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);
    final localUserAccount = localUserAccountBox.get(localUserId)!;

    if (localUserAccount.settings.isBiometricAuthenticationEnabled) {
      final localAuthSuccess = await _localAuthService
          .authenticateLocalUser("Authenticate to log back in"); //TODO: INTL
      if (!localAuthSuccess) {
        emit(const AuthenticationState.requriresLocalAuthentication());
        return;
      }
    }

    final authentication =
        await withEncryptedBox<UserCredentials, UserCredentials>(
            HiveBoxes.localUserCredentials, (box) {
      return box.get(globalSettings.currentLoggedInUser!);
    });

    if (authentication == null) {
      throw Exception(
          "User should be authenticated but no authentication information was found."); //TODO: INTL
    }
    _sessionManager.updateSettings(
      clientCertificate: authentication.clientCertificate,
      authToken: authentication.token,
      baseUrl: localUserAccount.serverUrl,
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
  }

  Future<void> logout() async {
    await _resetExternalState();
    final globalSettings =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
    globalSettings.currentLoggedInUser = null;
    await globalSettings.save();
    emit(const AuthenticationState.unauthenticated());
  }

  Future<void> _resetExternalState() async {
    _sessionManager.resetSettings();
    await HydratedBloc.storage.clear();
  }

  Future<int> _addUser(
    String localUserId,
    String serverUrl,
    LoginFormCredentials credentials,
    ClientCertificate? clientCert,
    SessionManager sessionManager,
  ) async {
    assert(credentials.username != null && credentials.password != null);

    sessionManager.updateSettings(
      baseUrl: serverUrl,
      clientCertificate: clientCert,
    );

    final authApi = _apiFactory.createAuthenticationApi(sessionManager.client);

    final token = await authApi.login(
      username: credentials.username!,
      password: credentials.password!,
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
      throw Exception("User already exists!");
    }
    final apiVersion = await _getApiVersion(sessionManager.client);

    final serverUser = await _apiFactory
        .createUserApi(
          sessionManager.client,
          apiVersion: apiVersion,
        )
        .findCurrentUser();

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

    // Create user state
    await userStateBox.put(
      localUserId,
      LocalUserAppState(userId: localUserId),
    );

    // Save credentials in encrypted box
    await withEncryptedBox(HiveBoxes.localUserCredentials, (box) async {
      await box.put(
        localUserId,
        UserCredentials(
          token: token,
          clientCertificate: clientCert,
        ),
      );
    });
    final hostsBox = Hive.box<String>(HiveBoxes.hosts);
    if (!hostsBox.values.contains(serverUrl)) {
      await hostsBox.add(serverUrl);
    }
    return serverUser.id;
  }

  Future<int> _getApiVersion(Dio dio) async {
    final response = await dio.get("/api/");
    return int.parse(response.headers.value('x-api-version') ?? "3");
  }

  /// Fetches possibly updated (permissions, name, updated server version and thus new user model, ...) remote user data.
  Future<void> _updateRemoteUser(
    SessionManager sessionManager,
    LocalUserAccount localUserAccount,
    int apiVersion,
  ) async {
    final updatedPaperlessUser = await _apiFactory
        .createUserApi(
          sessionManager.client,
          apiVersion: apiVersion,
        )
        .findCurrentUser();
    localUserAccount.paperlessUser = updatedPaperlessUser;
    await localUserAccount.save();
  }
}
