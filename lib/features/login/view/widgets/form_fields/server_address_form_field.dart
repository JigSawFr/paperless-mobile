import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';

import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class ServerAddressFormField extends StatefulWidget {
  static const String fkServerAddress = "serverAddress";

  final void Function(String? address) onSubmit;
  const ServerAddressFormField({
    Key? key,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<ServerAddressFormField> createState() => _ServerAddressFormFieldState();
}

class _ServerAddressFormFieldState extends State<ServerAddressFormField> {
  bool _canClear = false;

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() {
      setState(() {
        _canClear = _textEditingController.text.isNotEmpty;
      });
    });
  }

  final _focusNode = FocusNode();
  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<String>(
      name: ServerAddressFormField.fkServerAddress,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return S.of(context)!.serverAddressMustNotBeEmpty;
        }
        if (!RegExp(r"https?://.*").hasMatch(value!)) {
          return S.of(context)!.serverAddressMustIncludeAScheme;
        }
        return null;
      },
      builder: (field) {
        return RawAutocomplete<String>(
          focusNode: _focusNode,
          textEditingController: _textEditingController,
          optionsViewBuilder: (context, onSelected, options) {
            return _AutocompleteOptions(
              onSelected: onSelected,
              options: options,
              maxOptionsHeight: 200.0,
            );
          },
          key: const ValueKey('login-server-address'),
          optionsBuilder: (textEditingValue) {
            return Hive.box<String>(HiveBoxes.hosts)
                .values
                .where((element) => element.contains(textEditingValue.text));
          },
          onSelected: (option) => _formatInput(),
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: "http://192.168.1.50:8000",
                labelText: S.of(context)!.serverAddress,
                suffixIcon: _canClear
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        color: Theme.of(context).iconTheme.color,
                        onPressed: () {
                          textEditingController.clear();
                          field.didChange(textEditingController.text);
                          widget.onSubmit(textEditingController.text);
                        },
                      )
                    : null,
              ),
              autofocus: true,
              onSubmitted: (_) {
                onFieldSubmitted();
                _formatInput();
              },
              keyboardType: TextInputType.url,
              onChanged: (value) {
                field.didChange(value);
              },
              onEditingComplete: () {
                field.didChange(_textEditingController.text);
                _focusNode.unfocus();
              },
            );
          },
        );
      },
    );
  }

  void _formatInput() {
    String address = _textEditingController.text.trim();
    address = address.replaceAll(RegExp(r'^\/+|\/+$'), '');
    _textEditingController.text = address;
    widget.onSubmit(address);
  }
}

/// Taken from [Autocomplete]
class _AutocompleteOptions extends StatelessWidget {
  const _AutocompleteOptions({
    required this.onSelected,
    required this.options,
    required this.maxOptionsHeight,
  });

  final AutocompleteOnSelected<String> onSelected;

  final Iterable<String> options;
  final double maxOptionsHeight;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxOptionsHeight),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final option = options.elementAt(index);
              return InkWell(
                onTap: () {
                  onSelected(option);
                },
                child: Builder(builder: (BuildContext context) {
                  final bool highlight =
                      AutocompleteHighlightedOption.of(context) == index;
                  if (highlight) {
                    SchedulerBinding.instance
                        .addPostFrameCallback((Duration timeStamp) {
                      Scrollable.ensureVisible(context, alignment: 0.5);
                    });
                  }
                  return Container(
                    color: highlight ? Theme.of(context).focusColor : null,
                    padding: const EdgeInsets.all(16.0),
                    child: Text(option),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
