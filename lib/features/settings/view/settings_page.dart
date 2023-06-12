import 'package:flutter/material.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/features/settings/view/pages/application_settings_page.dart';
import 'package:paperless_mobile/features/settings/view/pages/security_settings_page.dart';
import 'package:paperless_mobile/features/settings/view/widgets/user_settings_builder.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.settings),
      ),
      bottomNavigationBar: UserAccountBuilder(
        builder: (context, user) {
          assert(user != null);
          final host = user!.serverUrl.replaceFirst(RegExp(r"https?://"), "");
          return ListTile(
            title: Text(
              S.of(context)!.loggedInAs(user.paperlessUser.username) + "@$host",
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
            subtitle: FutureBuilder<PaperlessServerInformationModel>(
              future: context
                  .read<PaperlessServerStatsApi>()
                  .getServerInformation(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    S.of(context)!.errorRetrievingServerVersion,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  );
                }
                if (!snapshot.hasData) {
                  return Text(
                    S.of(context)!.resolvingServerVersion,
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  );
                }
                final serverData = snapshot.data!;
                return Text(
                  S.of(context)!.paperlessServerVersion +
                      ' ' +
                      serverData.version.toString() +
                      ' (API v${serverData.apiVersion})',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          );
        },
      ),
      body: ListView(
        children: [
          ListTile(
            // leading: const Icon(Icons.style_outlined),
            title: Text(S.of(context)!.applicationSettings),
            subtitle: Text(S.of(context)!.languageAndVisualAppearance),
            onTap: () => _goto(const ApplicationSettingsPage(), context),
          ),
          ListTile(
            // leading: const Icon(Icons.security_outlined),
            title: Text(S.of(context)!.security),
            subtitle: Text(S.of(context)!.biometricAuthentication),
            onTap: () => _goto(const SecuritySettingsPage(), context),
          ),
          // ListTile(
          //   // leading: const Icon(Icons.storage_outlined),
          //   title: Text(S.of(context)!.storage),
          //   subtitle:
          //       Text(S.of(context)!.mangeFilesAndStorageSpace),
          //   onTap: () => _goto(const StorageSettingsPage(), context),
          // ),
        ],
      ),
    );
  }

  void _goto(Widget page, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        maintainState: true,
      ),
    );
  }
}
