import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/features/login/cubit/authentication_cubit.dart';
import 'package:paperless_mobile/features/login/model/client_certificate.dart';
import 'package:paperless_mobile/features/login/model/client_certificate_form_model.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/client_certificate_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/user_credentials_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/login_pages/server_connection_page.dart';
import 'package:paperless_mobile/features/users/view/widgets/user_account_list_tile.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';

import 'widgets/login_pages/server_login_page.dart';
import 'widgets/never_scrollable_scroll_behavior.dart';

class LoginPage extends StatefulWidget {
  final FutureOr<void> Function(
    BuildContext context,
    String username,
    String password,
    String serverUrl,
    ClientCertificate? clientCertificate,
  ) onSubmit;

  final String submitText;
  final String titleString;

  final bool showLocalAccounts;

  const LoginPage({
    Key? key,
    required this.onSubmit,
    required this.submitText,
    required this.titleString,
    this.showLocalAccounts = false,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final localAccounts =
        Hive.box<LocalUserAccount>(HiveBoxes.localUserAccount);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: FormBuilder(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          scrollBehavior: NeverScrollableScrollBehavior(),
          children: [
            if (widget.showLocalAccounts && localAccounts.isNotEmpty)
              Scaffold(
                appBar: AppBar(
                  title: Text(S.of(context)!.logInToExistingAccount),
                ),
                bottomNavigationBar: BottomAppBar(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        child: Text(S.of(context)!.goToLogin),
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                body: ListView.builder(
                  itemBuilder: (context, index) {
                    final account = localAccounts.values.elementAt(index);
                    return Card(
                      child: UserAccountListTile(
                        account: account,
                        onTap: () {
                          context
                              .read<AuthenticationCubit>()
                              .switchAccount(account.id);
                        },
                      ),
                    );
                  },
                  itemCount: localAccounts.length,
                ),
              ),
            ServerConnectionPage(
              titleString: widget.titleString,
              formBuilderKey: _formKey,
              onContinue: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            ServerLoginPage(
              formBuilderKey: _formKey,
              submitText: widget.submitText,
              onSubmit: _login,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final form = _formKey.currentState!.value;
      ClientCertificate? clientCert;
      final clientCertFormModel =
          form[ClientCertificateFormField.fkClientCertificate]
              as ClientCertificateFormModel?;
      if (clientCertFormModel != null) {
        clientCert = ClientCertificate(
          bytes: clientCertFormModel.bytes,
          passphrase: clientCertFormModel.passphrase,
        );
      }
      final credentials =
          form[UserCredentialsFormField.fkCredentials] as LoginFormCredentials;
      try {
        await widget.onSubmit(
          context,
          credentials.username!,
          credentials.password!,
          form[ServerAddressFormField.fkServerAddress],
          clientCert,
        );
      } on Exception catch (error) {
        showGenericError(context, error);
      }
    }
  }
}
