import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/features/home/view/model/api_version.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/view/login_page.dart';
import 'package:paperless_mobile/features/settings/view/dialogs/switch_account_dialog.dart';
import 'package:paperless_mobile/features/settings/view/widgets/global_settings_builder.dart';
import 'package:paperless_mobile/features/users/view/widgets/user_account_list_tile.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ManageAccountsPage extends StatelessWidget {
  const ManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalSettingsBuilder(
      builder: (context, globalSettings) {
        // This is one of the few places where the currentLoggedInUser can be null
        // (exactly after loggin out as the current user to be precise).
        if (globalSettings.currentLoggedInUser == null) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder(
          valueListenable:
              Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount)
                  .listenable(),
          builder: (context, box, _) {
            final userIds = box.keys.toList().cast<String>();
            final otherAccounts = userIds
                .whereNot(
                    (element) => element == globalSettings.currentLoggedInUser)
                .toList();
            return SimpleDialog(
              insetPadding: const EdgeInsets.all(24),
              contentPadding: const EdgeInsets.all(8),
              title: Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: CloseButton(),
                  ),
                  Center(child: Text(S.of(context)!.accounts)),
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              children: [
                Card(
                  child: UserAccountListTile(
                    account: box.get(globalSettings.currentLoggedInUser!)!,
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: ListTile(
                            title: Text(S.of(context)!.logout),
                            leading: const Icon(
                              Icons.person_remove,
                              color: Colors.red,
                            ),
                          ),
                          value: 0,
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 0) {
                          final currentUser =
                              globalSettings.currentLoggedInUser!;
                          await context.read<AuthenticationCubit>().logout();
                          Navigator.of(context).pop();
                          await context
                              .read<AuthenticationCubit>()
                              .removeAccount(currentUser);
                        }
                      },
                    ),
                  ),
                ),
                Column(
                  children: [
                    for (int index = 0; index < otherAccounts.length; index++)
                      UserAccountListTile(
                        account: box.get(otherAccounts[index])!,
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) {
                            return [
                              PopupMenuItem(
                                child: ListTile(
                                  title: Text(S.of(context)!.switchAccount),
                                  leading:
                                      const Icon(Icons.switch_account_rounded),
                                ),
                                value: 0,
                              ),
                              PopupMenuItem(
                                child: ListTile(
                                  title: Text(S.of(context)!.remove),
                                  leading: const Icon(
                                    Icons.person_remove,
                                    color: Colors.red,
                                  ),
                                ),
                                value: 1,
                              )
                            ];
                          },
                          onSelected: (value) async {
                            if (value == 0) {
                              // Switch
                              _onSwitchAccount(
                                context,
                                globalSettings.currentLoggedInUser!,
                                otherAccounts[index],
                              );
                            } else if (value == 1) {
                              await context
                                  .read<AuthenticationCubit>()
                                  .removeAccount(otherAccounts[index]);
                            }
                          },
                        ),
                      ),
                  ],
                ),
                const Divider(),
                ListTile(
                  title: Text(S.of(context)!.addAccount),
                  leading: const Icon(Icons.person_add),
                  onTap: () {
                    _onAddAccount(context, globalSettings.currentLoggedInUser!);
                  },
                ),
                if (context.watch<ApiVersion>().hasMultiUserSupport)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: Text(S.of(context)!.managePermissions),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _onAddAccount(BuildContext context, String currentUser) async {
    final userId = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          titleString: S.of(context)!.addAccount,
          onSubmit: (context, username, password, serverUrl,
              clientCertificate) async {
            final userId = await context.read<AuthenticationCubit>().addAccount(
                  credentials: LoginFormCredentials(
                    username: username,
                    password: password,
                  ),
                  clientCertificate: clientCertificate,
                  serverUrl: serverUrl,
                  //TODO: Ask user whether to enable biometric authentication
                  enableBiometricAuthentication: false,
                );
            Navigator.of(context).pop<String?>(userId);
          },
          submitText: S.of(context)!.addAccount,
        ),
      ),
    );
    if (userId != null) {
      final shoudSwitch = await showDialog<bool>(
            context: context,
            builder: (context) => const SwitchAccountDialog(),
          ) ??
          false;
      if (shoudSwitch) {
        _onSwitchAccount(context, currentUser, userId);
      }
    }
  }

  void _onSwitchAccount(
      BuildContext context, String currentUser, String newUser) async {
    if (currentUser == newUser) return;

    Navigator.of(context).pop();
    await context.read<AuthenticationCubit>().switchAccount(newUser);
  }
}
