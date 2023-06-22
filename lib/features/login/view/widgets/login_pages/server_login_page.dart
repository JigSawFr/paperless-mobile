import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/server_address_form_field.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/user_credentials_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ServerLoginPage extends StatefulWidget {
  final String submitText;
  final Future<void> Function() onSubmit;
  final GlobalKey<FormBuilderState> formBuilderKey;

  const ServerLoginPage({
    super.key,
    required this.onSubmit,
    required this.formBuilderKey,
    required this.submitText,
  });

  @override
  State<ServerLoginPage> createState() => _ServerLoginPageState();
}

class _ServerLoginPageState extends State<ServerLoginPage> {
  bool _isLoginLoading = false;
  @override
  Widget build(BuildContext context) {
    final serverAddress = (widget.formBuilderKey.currentState
                    ?.getRawValue(ServerAddressFormField.fkServerAddress)
                as String?)
            ?.replaceAll(RegExp(r'https?://'), '') ??
        '';
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context)!.loginPageSignInTitle),
        bottom: _isLoginLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4.0),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      body: ListView(
        children: [
          Text(
            S.of(context)!.signInToServer(serverAddress) + ":",
            style: Theme.of(context).textTheme.labelLarge,
          ).padded(16),
          UserCredentialsFormField(
            onFieldsSubmitted: widget.onSubmit,
          ),
          Text(
            S.of(context)!.loginRequiredPermissionsHint,
            style: Theme.of(context).textTheme.bodySmall?.apply(
                color: Theme.of(context)
                    .colorScheme
                    .onBackground
                    .withOpacity(0.6)),
          ).padded(16),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FilledButton(
              onPressed: () async {
                setState(() => _isLoginLoading = true);
                await widget.onSubmit();
                setState(() => _isLoginLoading = false);
              },
              child: Text(S.of(context)!.signIn),
            )
          ],
        ),
      ),
    );
  }
}
