import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

class FullscreenLabelForm<T extends Label> extends StatefulWidget {
  final IdQueryParameter? initialValue;

  final Map<int, T> options;
  final Future<T?> Function(String? initialName)? onCreateNewLabel;
  final bool showNotAssignedOption;
  final bool showAnyAssignedOption;
  final void Function({IdQueryParameter returnValue}) onSubmit;
  final Widget leadingIcon;
  final String? addNewLabelText;
  final bool autofocus;
  final bool allowSelectUnassigned;
  final bool canCreateNewLabel;

  FullscreenLabelForm({
    super.key,
    this.initialValue,
    required this.options,
    required this.onCreateNewLabel,
    this.showNotAssignedOption = true,
    this.showAnyAssignedOption = true,
    required this.onSubmit,
    required this.leadingIcon,
    this.addNewLabelText,
    this.autofocus = true,
    this.allowSelectUnassigned = true,
    required this.canCreateNewLabel,
  })  : assert(
          !(initialValue?.isOnlyAssigned() ?? false) || showAnyAssignedOption,
        ),
        assert(
          !(initialValue?.isOnlyNotAssigned() ?? false) ||
              showNotAssignedOption,
        ),
        assert((addNewLabelText != null) == (onCreateNewLabel != null));

  @override
  State<FullscreenLabelForm> createState() => _FullscreenLabelFormState();
}

class _FullscreenLabelFormState<T extends Label>
    extends State<FullscreenLabelForm<T>> {
  bool _showClearIcon = false;
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(() => setState(() {
          _showClearIcon = _textEditingController.text.isNotEmpty;
        }));
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        //Delay keyboard popup to ensure open animation is finished before.
        Future.delayed(
          const Duration(milliseconds: 200),
          () => _focusNode.requestFocus(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _filterOptionsByQuery(_textEditingController.text);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        toolbarHeight: 72,
        leading: BackButton(
          color: theme.colorScheme.onSurface,
        ),
        title: TextFormField(
          focusNode: _focusNode,
          controller: _textEditingController,
          onFieldSubmitted: (value) {
            FocusScope.of(context).unfocus();
            final index = AutocompleteHighlightedOption.of(context);
            final value = index.isNegative ? null : options.elementAt(index);
            widget.onSubmit(
              returnValue: value?.maybeWhen(
                    fromId: (id) => IdQueryParameter.fromId(id),
                    orElse: () => const IdQueryParameter.unset(),
                  ) ??
                  const IdQueryParameter.unset(),
            );
          },
          autofocus: true,
          style: theme.textTheme.bodyLarge?.apply(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            hintStyle: theme.textTheme.bodyLarge?.apply(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            icon: widget.leadingIcon,
            hintText: _buildHintText(),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          if (_showClearIcon)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _textEditingController.clear();
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            color: theme.colorScheme.outline,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final option = options.elementAt(index);
                    final highlight =
                        AutocompleteHighlightedOption.of(context) == index;
                    if (highlight) {
                      SchedulerBinding.instance
                          .addPostFrameCallback((Duration timeStamp) {
                        Scrollable.ensureVisible(
                          context,
                          alignment: 0,
                        );
                      });
                    }
                    return _buildOptionWidget(option, highlight);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onCreateNewLabel() async {
    final label = await widget.onCreateNewLabel!(_textEditingController.text);
    if (label?.id != null) {
      widget.onSubmit(
        returnValue: IdQueryParameter.fromId(label!.id!),
      );
    }
  }

  ///
  /// Filters the options passed to this widget by the current [query] and
  /// adds not-/any assigned options
  ///
  Iterable<IdQueryParameter> _filterOptionsByQuery(String query) sync* {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      if (widget.initialValue == null) {
        // If nothing is selected yet, show all options first.
        for (final option in widget.options.values) {
          yield IdQueryParameter.fromId(option.id!);
        }
        if (widget.showNotAssignedOption) {
          yield const IdQueryParameter.notAssigned();
        }
        if (widget.showAnyAssignedOption) {
          yield const IdQueryParameter.anyAssigned();
        }
      } else {
        // If an initial value is given, show not assigned first, which will be selected by default when pressing "done" on keyboard.
        if (widget.showNotAssignedOption) {
          yield const IdQueryParameter.notAssigned();
        }
        if (widget.showAnyAssignedOption) {
          yield const IdQueryParameter.anyAssigned();
        }
        for (final option in widget.options.values) {
          // Don't include the initial value in the selection
          final initialValue = widget.initialValue;
          if (initialValue is SetIdQueryParameter &&
              option.id == initialValue.id) {
            continue;
          }
          yield IdQueryParameter.fromId(option.id!);
        }
      }
    } else {
      // Show filtered options, if no matching option is found, always show not assigned and any assigned (if enabled) and proceed.
      final matches = widget.options.values
          .where((e) => e.name.trim().toLowerCase().contains(normalizedQuery));
      if (matches.isNotEmpty) {
        for (final match in matches) {
          yield IdQueryParameter.fromId(match.id!);
        }
        if (widget.showNotAssignedOption) {
          yield const IdQueryParameter.notAssigned();
        }
        if (widget.showAnyAssignedOption) {
          yield const IdQueryParameter.anyAssigned();
        }
      } else {
        if (widget.showNotAssignedOption) {
          yield const IdQueryParameter.notAssigned();
        }
        if (widget.showAnyAssignedOption) {
          yield const IdQueryParameter.anyAssigned();
        }
        if (!(widget.showAnyAssignedOption || widget.showNotAssignedOption)) {
          yield const IdQueryParameter.unset();
        }
      }
    }
  }

  String? _buildHintText() {
    return widget.initialValue?.when(
      unset: () => S.of(context)!.startTyping,
      notAssigned: () => S.of(context)!.notAssigned,
      anyAssigned: () => S.of(context)!.anyAssigned,
      fromId: (id) => widget.options[id]?.name ?? S.of(context)!.startTyping,
    );
  }

  Widget _buildOptionWidget(IdQueryParameter option, bool highlight) {
    void onTap() => widget.onSubmit(returnValue: option);

    if (option.isUnset()) {
      return Center(
        child: Column(
          children: [
            Text(S.of(context)!.noItemsFound).padded(),
            if (widget.onCreateNewLabel != null)
              TextButton(
                child: Text(widget.addNewLabelText!),
                onPressed: _onCreateNewLabel,
              ),
          ],
        ),
      );
    }

    return option.whenOrNull(
      notAssigned: () => ListTile(
        selected: highlight,
        selectedTileColor: Theme.of(context).focusColor,
        title: Text(S.of(context)!.notAssigned),
        onTap: onTap,
      ),
      anyAssigned: () => ListTile(
        selected: highlight,
        selectedTileColor: Theme.of(context).focusColor,
        title: Text(S.of(context)!.anyAssigned),
        onTap: onTap,
      ),
      fromId: (id) => ListTile(
        selected: highlight,
        selectedTileColor: Theme.of(context).focusColor,
        title: Text(widget.options[id]!.name),
        onTap: onTap,
        enabled: widget.allowSelectUnassigned
            ? true
            : widget.options[id]!.documentCount != 0,
      ),
    )!; // Never null, since we already return on unset before
  }
}
