import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_cancel_button.dart';
import 'package:paperless_mobile/core/widgets/dialog_utils/dialog_confirm_button.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ExportScansDialog extends StatefulWidget {
  const ExportScansDialog({super.key});

  @override
  State<ExportScansDialog> createState() => _ExportScansDialogState();
}

class _ExportScansDialogState extends State<ExportScansDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _filename;
  late String _placeholder;

  @override
  void initState() {
    super.initState();
    final date = DateFormat("yyyy_MM_ddThhmmss").format(DateTime.now());
    _placeholder = "paperless_mobile_scan_$date";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.all(8),
      title: Text(S.of(context)!.exportScansToPdf),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.of(context)!.allScansWillBeMerged),
            SizedBox(height: 16),
            TextFormField(
              onSaved: (newValue) {
                _filename = newValue;
              },
              autofocus: true,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final matches = RegExp(r'[<>:"/\|?*]').allMatches(value!);
                if (matches.isNotEmpty) {
                  final illegalCharacters = matches
                      .map((match) => match.group(0))
                      .toList()
                      .toSet()
                      .join(" ");
                  return S
                      .of(context)!
                      .invalidFilenameCharacter(illegalCharacters);
                }

                return null;
              },
              decoration: InputDecoration(
                labelText: S.of(context)!.fileName,
                errorMaxLines: 5,
                suffixText: ".pdf",
                hintText: _placeholder,
              ),
            ),
          ],
        ),
      ),
      actions: [
        const DialogCancelButton(),
        DialogConfirmButton(
          label: S.of(context)!.export,
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              final effectiveFilename = (_filename?.trim().isEmpty ?? true)
                  ? _placeholder
                  : _filename;
              Navigator.pop(context, effectiveFilename);
            }
          },
        ),
      ],
    );
  }
}
