import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mock_server/mock_server.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/constants.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/exception/server_message_exception.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory.dart';
import 'package:paperless_mobile/core/factory/paperless_api_factory_impl.dart';
import 'package:paperless_mobile/core/interceptor/language_header.interceptor.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/security/session_manager.dart';
import 'package:paperless_mobile/core/service/connectivity_status_service.dart';
import 'package:paperless_mobile/core/type/types.dart';
import 'package:paperless_mobile/features/app_intro/application_intro_slideshow.dart';
import 'package:paperless_mobile/features/home/view/home_route.dart';
import 'package:paperless_mobile/features/home/view/widget/verify_identity_page.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/services/authentication_service.dart';
import 'package:paperless_mobile/features/login/view/login_page.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/settings/view/pages/switching_accounts_page.dart';
import 'package:paperless_mobile/features/settings/view/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:paperless_mobile/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

String get defaultPreferredLocaleSubtag {
  String preferredLocale = Platform.localeName.split("_").first;
  if (!S.supportedLocales
      .any((locale) => locale.languageCode == preferredLocale)) {
    preferredLocale = 'en';
  }
  return preferredLocale;
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  registerHiveAdapters();
  // await getApplicationDocumentsDirectory().then((value) => value.deleteSync(recursive: true));
  await Hive.openBox<LocalUserAccount>(HiveBoxes.localUserAccount);
  await Hive.openBox<LocalUserAppState>(HiveBoxes.localUserAppState);
  await Hive.openBox<String>(HiveBoxes.hosts);
  final globalSettingsBox =
      await Hive.openBox<GlobalSettings>(HiveBoxes.globalSettings);

  if (!globalSettingsBox.hasValue) {
    await globalSettingsBox.setValue(
      GlobalSettings(preferredLocaleSubtag: defaultPreferredLocaleSubtag),
    );
  }
}

void main() async {
  runZonedGuarded(() async {
    Paint.enableDithering = true;
    if (kDebugMode) {
      // URL: http://localhost:3131
      // Login: admin:test
      await LocalMockApiServer(
              // RandomDelayGenerator(
              //   const Duration(milliseconds: 100),
              //   const Duration(milliseconds: 800),
              // ),
              )
          .start();
    }
    await _initHive();
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    final globalSettingsBox =
        Hive.box<GlobalSettings>(HiveBoxes.globalSettings);
    final globalSettings = globalSettingsBox.getValue()!;

    await findSystemLocale();
    packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isAndroid) {
      androidInfo = await DeviceInfoPlugin().androidInfo;
    }
    if (Platform.isIOS) {
      iosInfo = await DeviceInfoPlugin().iosInfo;
    }

    final connectivity = Connectivity();
    final localAuthentication = LocalAuthentication();
    final connectivityStatusService =
        ConnectivityStatusServiceImpl(connectivity);
    final localAuthService = LocalAuthenticationService(localAuthentication);

    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: await getApplicationDocumentsDirectory(),
    );

    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    final languageHeaderInterceptor = LanguageHeaderInterceptor(
      globalSettings.preferredLocaleSubtag,
    );
    // Manages security context, required for self signed client certificates
    final sessionManager = SessionManager([
      languageHeaderInterceptor,
    ]);

    // Initialize Blocs/Cubits
    final connectivityCubit = ConnectivityCubit(connectivityStatusService);

    // Load application settings and stored authentication data
    await connectivityCubit.initialize();

    final localNotificationService = LocalNotificationService();
    await localNotificationService.initialize();

    //Update language header in interceptor on language change.
    globalSettingsBox.listenable().addListener(() {
      languageHeaderInterceptor.preferredLocaleSubtag =
          globalSettings.preferredLocaleSubtag;
    });

    final apiFactory = PaperlessApiFactoryImpl(sessionManager);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sessionManager),
          Provider<LocalAuthenticationService>.value(value: localAuthService),
          Provider<Connectivity>.value(value: connectivity),
          Provider<ConnectivityStatusService>.value(
              value: connectivityStatusService),
          Provider<LocalNotificationService>.value(
              value: localNotificationService),
          Provider.value(value: DocumentChangedNotifier()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
            BlocProvider(
              create: (context) => AuthenticationCubit(
                  localAuthService, apiFactory, sessionManager),
            ),
          ],
          child: PaperlessMobileEntrypoint(
            paperlessProviderFactory: apiFactory,
          ),
        ),
      ),
    );
  }, (error, stack) {
    String message = switch (error) {
      PaperlessServerException e => e.details ?? error.toString(),
      ServerMessageException e => e.message,
      _ => error.toString()
    };
    debugPrint("An unepxected exception has occured!");
    debugPrint(message);
    debugPrintStack(stackTrace: stack);
    // if (_rootScaffoldKey.currentContext != null) {
    //   ScaffoldMessenger.maybeOf(_rootScaffoldKey.currentContext!)
    //     ?..hideCurrentSnackBar()
    //     ..showSnackBar(SnackBar(content: Text(message)));
    // }
  });
}

class PaperlessMobileEntrypoint extends StatefulWidget {
  final PaperlessApiFactory paperlessProviderFactory;
  const PaperlessMobileEntrypoint({
    Key? key,
    required this.paperlessProviderFactory,
  }) : super(key: key);

  @override
  State<PaperlessMobileEntrypoint> createState() =>
      _PaperlessMobileEntrypointState();
}

class _PaperlessMobileEntrypointState extends State<PaperlessMobileEntrypoint> {
  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, settings) {
        return DynamicColorBuilder(
          builder: (lightDynamic, darkDynamic) {
            return MaterialApp(
              debugShowCheckedModeBanner: true,
              title: "Paperless Mobile",
              theme: buildTheme(
                brightness: Brightness.light,
                dynamicScheme: lightDynamic,
                preferredColorScheme: settings.preferredColorSchemeOption,
              ),
              darkTheme: buildTheme(
                brightness: Brightness.dark,
                dynamicScheme: darkDynamic,
                preferredColorScheme: settings.preferredColorSchemeOption,
              ),
              themeMode: settings.preferredThemeMode,
              supportedLocales: S.supportedLocales,
              locale: Locale.fromSubtags(
                languageCode: settings.preferredLocaleSubtag,
              ),
              localizationsDelegates: const [
                ...S.localizationsDelegates,
              ],
              home: AuthenticationWrapper(
                paperlessProviderFactory: widget.paperlessProviderFactory,
              ),
            );
          },
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  final PaperlessApiFactory paperlessProviderFactory;

  const AuthenticationWrapper({
    Key? key,
    required this.paperlessProviderFactory,
  }) : super(key: key);

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<AuthenticationCubit>().restoreSessionState().then((value) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  void initState() {
    super.initState();

    // Activate the highest supported refresh rate on the device
    if (Platform.isAndroid) {
      _setOptimalDisplayMode();
    }
    initializeDateFormatting();
  }

  Future<void> _setOptimalDisplayMode() async {
    final List<DisplayMode> supported = await FlutterDisplayMode.supported;
    final DisplayMode active = await FlutterDisplayMode.active;

    final List<DisplayMode> sameResolution = supported
        .where((m) => m.width == active.width && m.height == active.height)
        .toList()
      ..sort((a, b) => b.refreshRate.compareTo(a.refreshRate));

    final DisplayMode mostOptimalMode =
        sameResolution.isNotEmpty ? sameResolution.first : active;
    debugPrint('Setting refresh rate to ${mostOptimalMode.refreshRate}');

    await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationCubit, AuthenticationState>(
      builder: (context, authentication) {
        return authentication.when(
          unauthenticated: () => LoginPage(
            titleString: S.of(context)!.connectToPaperless,
            submitText: S.of(context)!.signIn,
            onSubmit: _onLogin,
            showLocalAccounts: true,
          ),
          requriresLocalAuthentication: () => const VerifyIdentityPage(),
          authenticated: (localUserId, apiVersion) => HomeRoute(
            key: ValueKey(localUserId),
            paperlessApiVersion: apiVersion,
            paperlessProviderFactory: widget.paperlessProviderFactory,
            localUserId: localUserId,
          ),
          switchingAccounts: () => const SwitchingAccountsPage(),
        );
      },
    );
  }

  void _onLogin(
    BuildContext context,
    String username,
    String password,
    String serverUrl,
    ClientCertificate? clientCertificate,
  ) async {
    try {
      await context.read<AuthenticationCubit>().login(
            credentials:
                LoginFormCredentials(username: username, password: password),
            serverUrl: serverUrl,
            clientCertificate: clientCertificate,
          );
      // Show onboarding after first login!
      final globalSettings =
          Hive.box<GlobalSettings>(HiveBoxes.globalSettings).getValue()!;
      if (globalSettings.showOnboarding) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ApplicationIntroSlideshow(),
            fullscreenDialog: true,
          ),
        ).then((value) {
          globalSettings.showOnboarding = false;
          globalSettings.save();
        });
      }
    } on PaperlessServerException catch (error, stackTrace) {
      showErrorMessage(context, error, stackTrace);
    } on PaperlessValidationErrors catch (error, stackTrace) {
      if (error.hasFieldUnspecificError) {
        showLocalizedError(context, error.fieldUnspecificError!);
      } else {
        showGenericError(context, error.values.first, stackTrace);
      }
    } catch (unknownError, stackTrace) {
      showGenericError(context, unknownError.toString(), stackTrace);
    }
  }
}
