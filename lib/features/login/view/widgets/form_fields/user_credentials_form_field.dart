import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/model/login_form_credentials.dart';
import 'package:paperless_mobile/features/login/view/widgets/form_fields/obscured_input_text_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class UserCredentialsFormField extends StatefulWidget {
  static const fkCredentials = 'credentials';

  final void Function() onFieldsSubmitted;

  const UserCredentialsFormField({
    Key? key,
    required this.onFieldsSubmitted,
  }) : super(key: key);

  @override
  State<UserCredentialsFormField> createState() =>
      _UserCredentialsFormFieldState();
}

class _UserCredentialsFormFieldState extends State<UserCredentialsFormField> {
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<LoginFormCredentials?>(
      name: UserCredentialsFormField.fkCredentials,
      builder: (field) => AutofillGroup(
        child: Column(
          children: [
            TextFormField(
              key: const ValueKey('login-username'),
              focusNode: _usernameFocusNode,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (value) {
                _passwordFocusNode.requestFocus();
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
              autocorrect: false,
              onChanged: (username) => field.didChange(
                field.value?.copyWith(username: username) ??
                    LoginFormCredentials(username: username),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.usernameMustNotBeEmpty;
                }
                return null;
              },
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                label: Text(S.of(context)!.username),
              ),
            ),
            ObscuredInputTextFormField(
              key: const ValueKey('login-password'),
              focusNode: _passwordFocusNode,
              label: S.of(context)!.password,
              onChanged: (password) => field.didChange(
                field.value?.copyWith(password: password) ??
                    LoginFormCredentials(password: password),
              ),
              onFieldSubmitted: (_) {
                widget.onFieldsSubmitted();
              },
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return S.of(context)!.passwordMustNotBeEmpty;
                }
                return null;
              },
            ),
          ].map((child) => child.padded()).toList(),
        ),
      ),
    );
  }
}

/**
 * AutofillGroup(
      child: Column(
        children: [
          FormBuilderTextField(
            name: fkUsername,
            focusNode: _focusNodes[fkUsername],
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_focusNodes[fkPassword]);
            },
            validator: FormBuilderValidators.required(
              errorText: S.of(context)!.usernameMustNotBeEmpty,
            ),
            autofillHints: const [AutofillHints.username],
            decoration: InputDecoration(
              labelText: S.of(context)!.username,
            ),
          ).padded(),
          FormBuilderTextField(
            name: fkPassword,
            focusNode: _focusNodes[fkPassword],
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
            autofillHints: const [AutofillHints.password],
            validator: FormBuilderValidators.required(
              errorText: S.of(context)!.passwordMustNotBeEmpty,
            ),
            obscureText: true,
            decoration: InputDecoration(
              labelText: S.of(context)!.password,
            ),
          ).padded(),
        ],
      ),
    );
 */
