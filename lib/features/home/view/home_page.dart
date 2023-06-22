import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/bloc/connectivity_cubit.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/global_settings.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/global/constants.dart';
import 'package:paperless_mobile/core/navigation/push_routes.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/repository/saved_view_repository.dart';
import 'package:paperless_mobile/core/service/file_description.dart';
import 'package:paperless_mobile/core/translation/error_code_localization_mapper.dart';
import 'package:paperless_mobile/features/document_scan/view/scanner_page.dart';
import 'package:paperless_mobile/features/documents/view/pages/documents_page.dart';
import 'package:paperless_mobile/features/home/view/route_description.dart';
import 'package:paperless_mobile/features/inbox/cubit/inbox_cubit.dart';
import 'package:paperless_mobile/features/inbox/view/pages/inbox_page.dart';
import 'package:paperless_mobile/features/labels/view/pages/labels_page.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:paperless_mobile/features/sharing/share_intent_queue.dart';
import 'package:paperless_mobile/features/tasks/cubit/task_status_cubit.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:responsive_builder/responsive_builder.dart';

/// Wrapper around all functionality for a logged in user.
/// Performs initialization logic.
class HomePage extends StatefulWidget {
  final int paperlessApiVersion;
  const HomePage({Key? key, required this.paperlessApiVersion})
      : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late Timer _inboxTimer;
  late final StreamSubscription _shareMediaSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToInboxChanges();
    final currentUser = Hive.box<GlobalSettings>(HiveBoxes.globalSettings)
        .getValue()!
        .currentLoggedInUser!;
    // For sharing files coming from outside the app while the app is still opened
    _shareMediaSubscription = ReceiveSharingIntent.getMediaStream().listen(
        (files) =>
            ShareIntentQueue.instance.addAll(files, userId: currentUser));
    // For sharing files coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((files) =>
        ShareIntentQueue.instance.addAll(files, userId: currentUser));
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _listenForReceivedFiles();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _listenToInboxChanges() {
    _inboxTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
      } else {
        context.read<InboxCubit>().refreshItemsInInboxCount();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        log('App is now in foreground');
        context.read<ConnectivityCubit>().reload();
        log("Reloaded device connectivity state");
        if (!_inboxTimer.isActive) {
          _listenToInboxChanges();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      default:
        log('App is now in background');
        _inboxTimer.cancel();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxTimer.cancel();
    _shareMediaSubscription.cancel();
    super.dispose();
  }

  void _listenForReceivedFiles() async {
    final currentUser = Hive.box<GlobalSettings>(HiveBoxes.globalSettings)
        .getValue()!
        .currentLoggedInUser!;
    if (ShareIntentQueue.instance.userHasUnhandlesFiles(currentUser)) {
      await _handleReceivedFile(ShareIntentQueue.instance.pop(currentUser)!);
    }
    ShareIntentQueue.instance.addListener(() async {
      final queue = ShareIntentQueue.instance;
      while (queue.userHasUnhandlesFiles(currentUser)) {
        final file = queue.pop(currentUser)!;
        await _handleReceivedFile(file);
      }
    });
  }

  bool _isFileTypeSupported(SharedMediaFile file) {
    return supportedFileExtensions.contains(
      file.path.split('.').last.toLowerCase(),
    );
  }

  Future<void> _handleReceivedFile(final SharedMediaFile file) async {
    SharedMediaFile mediaFile;
    if (Platform.isIOS) {
      // Workaround for file not found on iOS: https://stackoverflow.com/a/72813212
      mediaFile = SharedMediaFile(
        file.path.replaceAll('file://', ''),
        file.thumbnail,
        file.duration,
        file.type,
      );
    } else {
      mediaFile = file;
    }
    debugPrint("Consuming media file: ${mediaFile.path}");
    if (!_isFileTypeSupported(mediaFile)) {
      Fluttertoast.showToast(
        msg: translateError(context, ErrorCode.unsupportedFileFormat),
      );
      if (Platform.isAndroid) {
        // As stated in the docs, SystemNavigator.pop() is ignored on IOS to comply with HCI guidelines.
        await SystemNavigator.pop();
      }
      return;
    }

    if (!LocalUserAccount.current.paperlessUser
        .hasPermission(PermissionAction.add, PermissionTarget.document)) {
      Fluttertoast.showToast(
        msg: "You do not have the permissions to upload documents.",
      );
      return;
    }
    final fileDescription = FileDescription.fromPath(mediaFile.path);
    if (await File(mediaFile.path).exists()) {
      final bytes = await File(mediaFile.path).readAsBytes();
      final result = await pushDocumentUploadPreparationPage(
        context,
        bytes: bytes,
        filename: fileDescription.filename,
        title: fileDescription.filename,
        fileExtension: fileDescription.extension,
      );
      if (result?.success ?? false) {
        await Fluttertoast.showToast(
          msg: S.of(context)!.documentSuccessfullyUploadedProcessing,
        );
        SystemNavigator.pop();
      }
    } else {
      Fluttertoast.showToast(
        msg: S.of(context)!.couldNotAccessReceivedFile,
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      RouteDescription(
        icon: const Icon(Icons.description_outlined),
        selectedIcon: Icon(
          Icons.description,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: S.of(context)!.documents,
      ),
      if (LocalUserAccount.current.paperlessUser
          .hasPermission(PermissionAction.add, PermissionTarget.document))
        RouteDescription(
          icon: const Icon(Icons.document_scanner_outlined),
          selectedIcon: Icon(
            Icons.document_scanner,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: S.of(context)!.scanner,
        ),
      RouteDescription(
        icon: const Icon(Icons.sell_outlined),
        selectedIcon: Icon(
          Icons.sell,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: S.of(context)!.labels,
      ),
      RouteDescription(
        icon: const Icon(Icons.inbox_outlined),
        selectedIcon: Icon(
          Icons.inbox,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: S.of(context)!.inbox,
        badgeBuilder: (icon) => BlocBuilder<InboxCubit, InboxState>(
          builder: (context, state) {
            return Badge.count(
              isLabelVisible: state.itemsInInboxCount > 0,
              count: state.itemsInInboxCount,
              child: icon,
            );
          },
        ),
      ),
    ];
    final routes = <Widget>[
      const DocumentsPage(),
      if (LocalUserAccount.current.paperlessUser.hasPermission(
        PermissionAction.add,
        PermissionTarget.document,
      ))
        const ScannerPage(),
      const LabelsPage(),
      const InboxPage(),
    ];
    return MultiBlocListener(
      listeners: [
        BlocListener<ConnectivityCubit, ConnectivityState>(
          // If app was started offline, load data once it comes back online.
          listenWhen: (previous, current) =>
              previous != ConnectivityState.connected &&
              current == ConnectivityState.connected,
          listener: (context, state) async {
            try {
              debugPrint(
                "[HomePage] BlocListener#listener: "
                "Loading saved views and labels...",
              );
              await Future.wait([
                context.read<LabelRepository>().initialize(),
                context.read<SavedViewRepository>().initialize(),
              ]);
              debugPrint("[HomePage] BlocListener#listener: "
                  "Saved views and labels successfully loaded.");
            } catch (error, stackTrace) {
              debugPrint(
                '[HomePage] BlocListener.listener: '
                'An error occurred while loading saved views and labels.\n'
                '${error.toString()}',
              );
              debugPrintStack(stackTrace: stackTrace);
            }
          },
        ),
        BlocListener<TaskStatusCubit, TaskStatusState>(
          listener: (context, state) {
            if (state.task != null) {
              // Handle local notifications on task change (only when app is running for now).
              context
                  .read<LocalNotificationService>()
                  .notifyTaskChanged(state.task!);
            }
          },
        ),
      ],
      child: ResponsiveBuilder(
        builder: (context, sizingInformation) {
          if (!sizingInformation.isMobile) {
            return Scaffold(
              body: Row(
                children: [
                  NavigationRail(
                    labelType: NavigationRailLabelType.all,
                    destinations: destinations
                        .map((e) => e.toNavigationRailDestination())
                        .toList(),
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onNavigationChanged,
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    child: routes[_currentIndex],
                  ),
                ],
              ),
            );
          }
          return Scaffold(
            bottomNavigationBar: NavigationBar(
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              elevation: 4.0,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onNavigationChanged,
              destinations:
                  destinations.map((e) => e.toNavigationDestination()).toList(),
            ),
            body: routes[_currentIndex],
          );
        },
      ),
    );
  }

  void _onNavigationChanged(index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }
}
