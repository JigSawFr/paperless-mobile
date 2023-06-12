import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/login/model/client_certificate_form_model.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

import 'obscured_input_text_form_field.dart';

class ClientCertificateFormField extends StatefulWidget {
  static const fkClientCertificate = 'clientCertificate';

  final void Function(ClientCertificateFormModel? cert) onChanged;
  const ClientCertificateFormField({
    Key? key,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ClientCertificateFormField> createState() =>
      _ClientCertificateFormFieldState();
}

class _ClientCertificateFormFieldState
    extends State<ClientCertificateFormField> {
  File? _selectedFile;
  @override
  Widget build(BuildContext context) {
    return FormBuilderField<ClientCertificateFormModel?>(
      key: const ValueKey('login-client-cert'),
      onChanged: widget.onChanged,
      initialValue: null,
      validator: (value) {
        if (value == null) {
          return null;
        }
        assert(_selectedFile != null);
        if (_selectedFile?.path.split(".").last != 'pfx') {
          return S.of(context)!.invalidCertificateFormat;
        }
        return null;
      },
      builder: (field) {
        final theme =
            Theme.of(context).copyWith(dividerColor: Colors.transparent); //new
        return Theme(
          data: theme,
          child: ExpansionTile(
            title: Text(S.of(context)!.clientcertificate),
            subtitle: Text(S.of(context)!.configureMutualTLSAuthentication),
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  errorText: field.errorText,
                  border: InputBorder.none,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _onSelectFile(field),
                              child: Text(S.of(context)!.select),
                            ),
                            _buildSelectedFileText(field).paddedOnly(left: 8),
                          ],
                        ),
                        if (_selectedFile != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _selectedFile = null;
                              field.didChange(null);
                            }),
                          )
                      ],
                    ).padded(8),
                    // ListTile(
                    //   leading: ElevatedButton(
                    //     onPressed: () => _onSelectFile(field),
                    //     child: Text(S.of(context)!.select),
                    //   ),
                    //   title: _buildSelectedFileText(field),
                    //   trailing: AbsorbPointer(
                    //     absorbing: field.value == null,
                    //     child: _selectedFile != null
                    //         ? IconButton(
                    //             icon: const Icon(Icons.close),
                    //             onPressed: () => setState(() {
                    //               _selectedFile = null;
                    //               field.didChange(null);
                    //             }),
                    //           )
                    //         : null,
                    //   ),
                    // ),
                    if (_selectedFile != null) ...[
                      ObscuredInputTextFormField(
                        key: const ValueKey('login-client-cert-passphrase'),
                        initialValue: field.value?.passphrase,
                        onChanged: (value) => field.didChange(
                          field.value?.copyWith(passphrase: value),
                        ),
                        label: S.of(context)!.passphrase,
                      ).padded(),
                    ] else
                      ...[]
                  ],
                ),
              ),
            ],
          ),
        );
      },
      name: ClientCertificateFormField.fkClientCertificate,
    );
  }

  Future<void> _onSelectFile(
      FormFieldState<ClientCertificateFormModel?> field) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
      });
      final changedValue =
          field.value?.copyWith(bytes: file.readAsBytesSync()) ??
              ClientCertificateFormModel(bytes: file.readAsBytesSync());
      field.didChange(changedValue);
    }
  }

  Widget _buildSelectedFileText(
      FormFieldState<ClientCertificateFormModel?> field) {
    if (field.value == null) {
      assert(_selectedFile == null);
      return Text(
        S.of(context)!.selectFile,
        style: Theme.of(context).textTheme.labelMedium?.apply(
              color: Theme.of(context).hintColor,
            ),
      );
    } else {
      assert(_selectedFile != null);
      return Text(
        _selectedFile!.path.split("/").last,
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}
