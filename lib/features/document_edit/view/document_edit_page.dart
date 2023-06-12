import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_account.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/workarounds/colored_chip.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_edit/cubit/document_edit_cubit.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_correspondent_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_document_type_page.dart';
import 'package:paperless_mobile/features/edit_label/view/impl/add_storage_path_page.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_form_field.dart';
import 'package:paperless_mobile/features/labels/view/widgets/label_form_field.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';

import 'package:paperless_mobile/helpers/message_helpers.dart';

class DocumentEditPage extends StatefulWidget {
  final FieldSuggestions? suggestions;
  const DocumentEditPage({
    Key? key,
    required this.suggestions,
  }) : super(key: key);

  @override
  State<DocumentEditPage> createState() => _DocumentEditPageState();
}

class _DocumentEditPageState extends State<DocumentEditPage> {
  static const fkTitle = "title";
  static const fkCorrespondent = "correspondent";
  static const fkTags = "tags";
  static const fkDocumentType = "documentType";
  static const fkCreatedDate = "createdAtDate";
  static const fkStoragePath = 'storagePath';
  static const fkContent = 'content';

  final GlobalKey<FormBuilderState> _formKey = GlobalKey();
  bool _isSubmitLoading = false;

  late final FieldSuggestions? _filteredSuggestions;

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = widget.suggestions
        ?.documentDifference(context.read<DocumentEditCubit>().state.document);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentEditCubit, DocumentEditState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
              resizeToAvoidBottomInset: false,
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _onSubmit(state.document),
                icon: const Icon(Icons.save),
                label: Text(S.of(context)!.saveChanges),
              ),
              appBar: AppBar(
                title: Text(S.of(context)!.editDocument),
                bottom: TabBar(
                  tabs: [
                    Tab(
                      text: S.of(context)!.overview,
                    ),
                    Tab(
                      text: S.of(context)!.content,
                    )
                  ],
                ),
              ),
              extendBody: true,
              body: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  top: 8,
                  left: 8,
                  right: 8,
                ),
                child: FormBuilder(
                  key: _formKey,
                  child: TabBarView(
                    children: [
                      ListView(
                        children: [
                          _buildTitleFormField(state.document.title).padded(),
                          _buildCreatedAtFormField(state.document.created)
                              .padded(),
                          // Correspondent form field
                          Column(
                            children: [
                              LabelFormField<Correspondent>(
                                showAnyAssignedOption: false,
                                showNotAssignedOption: false,
                                addLabelPageBuilder: (initialValue) =>
                                    RepositoryProvider.value(
                                  value: context.read<LabelRepository>(),
                                  child: AddCorrespondentPage(
                                    initialName: initialValue,
                                  ),
                                ),
                                addLabelText: S.of(context)!.addCorrespondent,
                                labelText: S.of(context)!.correspondent,
                                options: context
                                    .watch<DocumentEditCubit>()
                                    .state
                                    .correspondents,
                                initialValue:
                                    state.document.correspondent != null
                                        ? IdQueryParameter.fromId(
                                            state.document.correspondent!)
                                        : const IdQueryParameter.unset(),
                                name: fkCorrespondent,
                                prefixIcon: const Icon(Icons.person_outlined),
                                allowSelectUnassigned: true,
                                canCreateNewLabel: LocalUserAccount
                                    .current.paperlessUser
                                    .hasPermission(
                                  PermissionAction.add,
                                  PermissionTarget.correspondent,
                                ),
                              ),
                              if (_filteredSuggestions
                                      ?.hasSuggestedCorrespondents ??
                                  false)
                                _buildSuggestionsSkeleton<int>(
                                  suggestions:
                                      _filteredSuggestions!.correspondents,
                                  itemBuilder: (context, itemData) =>
                                      ActionChip(
                                    label: Text(
                                        state.correspondents[itemData]!.name),
                                    onPressed: () {
                                      _formKey
                                          .currentState?.fields[fkCorrespondent]
                                          ?.didChange(
                                        IdQueryParameter.fromId(itemData),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ).padded(),
                          // DocumentType form field
                          Column(
                            children: [
                              LabelFormField<DocumentType>(
                                showAnyAssignedOption: false,
                                showNotAssignedOption: false,
                                addLabelPageBuilder: (currentInput) =>
                                    RepositoryProvider.value(
                                  value: context.read<LabelRepository>(),
                                  child: AddDocumentTypePage(
                                    initialName: currentInput,
                                  ),
                                ),
                                canCreateNewLabel: LocalUserAccount
                                    .current.paperlessUser
                                    .hasPermission(
                                  PermissionAction.add,
                                  PermissionTarget.documentType,
                                ),
                                addLabelText: S.of(context)!.addDocumentType,
                                labelText: S.of(context)!.documentType,
                                initialValue:
                                    state.document.documentType != null
                                        ? IdQueryParameter.fromId(
                                            state.document.documentType!)
                                        : const IdQueryParameter.unset(),
                                options: state.documentTypes,
                                name: _DocumentEditPageState.fkDocumentType,
                                prefixIcon:
                                    const Icon(Icons.description_outlined),
                                allowSelectUnassigned: true,
                              ),
                              if (_filteredSuggestions
                                      ?.hasSuggestedDocumentTypes ??
                                  false)
                                _buildSuggestionsSkeleton<int>(
                                  suggestions:
                                      _filteredSuggestions!.documentTypes,
                                  itemBuilder: (context, itemData) =>
                                      ActionChip(
                                    label: Text(
                                        state.documentTypes[itemData]!.name),
                                    onPressed: () => _formKey
                                        .currentState?.fields[fkDocumentType]
                                        ?.didChange(
                                      IdQueryParameter.fromId(itemData),
                                    ),
                                  ),
                                ),
                            ],
                          ).padded(),
                          // StoragePath form field
                          Column(
                            children: [
                              LabelFormField<StoragePath>(
                                showAnyAssignedOption: false,
                                showNotAssignedOption: false,
                                addLabelPageBuilder: (initialValue) =>
                                    RepositoryProvider.value(
                                  value: context.read<LabelRepository>(),
                                  child: AddStoragePathPage(
                                      initalName: initialValue),
                                ),
                                canCreateNewLabel: LocalUserAccount
                                    .current.paperlessUser
                                    .hasPermission(
                                  PermissionAction.add,
                                  PermissionTarget.storagePath,
                                ),
                                addLabelText: S.of(context)!.addStoragePath,
                                labelText: S.of(context)!.storagePath,
                                options: state.storagePaths,
                                initialValue: state.document.storagePath != null
                                    ? IdQueryParameter.fromId(
                                        state.document.storagePath!)
                                    : const IdQueryParameter.unset(),
                                name: fkStoragePath,
                                prefixIcon: const Icon(Icons.folder_outlined),
                                allowSelectUnassigned: true,
                              ),
                            ],
                          ).padded(),
                          // Tag form field
                          TagsFormField(
                            options: state.tags,
                            name: fkTags,
                            allowOnlySelection: true,
                            allowCreation: true,
                            allowExclude: false,
                            initialValue: TagsQuery.ids(
                              include: state.document.tags.toList(),
                            ),
                          ).padded(),
                          if (_filteredSuggestions?.tags
                                  .toSet()
                                  .difference(state.document.tags.toSet())
                                  .isNotEmpty ??
                              false)
                            _buildSuggestionsSkeleton<int>(
                              suggestions:
                                  (_filteredSuggestions?.tags.toSet() ?? {}),
                              itemBuilder: (context, itemData) {
                                final tag = state.tags[itemData]!;
                                return ActionChip(
                                  label: Text(
                                    tag.name,
                                    style: TextStyle(color: tag.textColor),
                                  ),
                                  backgroundColor: tag.color,
                                  onPressed: () {
                                    final currentTags = _formKey.currentState
                                        ?.fields[fkTags]?.value as TagsQuery;
                                    _formKey.currentState?.fields[fkTags]
                                        ?.didChange(
                                      currentTags.maybeWhen(
                                        ids: (include, exclude) =>
                                            TagsQuery.ids(
                                                include: [...include, itemData],
                                                exclude: exclude),
                                        orElse: () =>
                                            TagsQuery.ids(include: [itemData]),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          // Prevent tags from being hidden by fab
                          const SizedBox(height: 64),
                        ],
                      ),
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            FormBuilderTextField(
                              name: fkContent,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              initialValue: state.document.content,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                            const SizedBox(height: 84),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        );
      },
    );
  }

  Future<void> _onSubmit(DocumentModel document) async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      var mergedDocument = document.copyWith(
        title: values[fkTitle],
        created: values[fkCreatedDate],
        documentType: () => (values[fkDocumentType] as IdQueryParameter)
            .whenOrNull(fromId: (id) => id),
        correspondent: () => (values[fkCorrespondent] as IdQueryParameter)
            .whenOrNull(fromId: (id) => id),
        storagePath: () => (values[fkStoragePath] as IdQueryParameter)
            .whenOrNull(fromId: (id) => id),
        tags: (values[fkTags] as IdsTagsQuery).include,
        content: values[fkContent],
      );
      setState(() {
        _isSubmitLoading = true;
      });
      try {
        await context.read<DocumentEditCubit>().updateDocument(mergedDocument);
        showSnackBar(context, S.of(context)!.documentSuccessfullyUpdated);
      } on PaperlessServerException catch (error, stackTrace) {
        showErrorMessage(context, error, stackTrace);
      } finally {
        setState(() {
          _isSubmitLoading = false;
        });
        Navigator.pop(context);
      }
    }
  }

  Widget _buildTitleFormField(String? initialTitle) {
    return FormBuilderTextField(
      name: fkTitle,
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return S.of(context)!.thisFieldIsRequired;
        }
        return null;
      },
      decoration: InputDecoration(
        label: Text(S.of(context)!.title),
      ),
      initialValue: initialTitle,
    );
  }

  Widget _buildCreatedAtFormField(DateTime? initialCreatedAtDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormBuilderDateTimePicker(
          inputType: InputType.date,
          name: fkCreatedDate,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            label: Text(S.of(context)!.createdAt),
          ),
          initialValue: initialCreatedAtDate,
          format: DateFormat.yMMMMd(),
          initialEntryMode: DatePickerEntryMode.calendar,
        ),
        if (_filteredSuggestions?.hasSuggestedDates ?? false)
          _buildSuggestionsSkeleton<DateTime>(
            suggestions: _filteredSuggestions!.dates,
            itemBuilder: (context, itemData) => ActionChip(
              label: Text(DateFormat.yMMMd().format(itemData)),
              onPressed: () => _formKey.currentState?.fields[fkCreatedDate]
                  ?.didChange(itemData),
            ),
          ),
      ],
    );
  }

  ///
  /// Item builder is typically some sort of [Chip].
  ///
  Widget _buildSuggestionsSkeleton<T>({
    required Iterable<T> suggestions,
    required ItemBuilder<T> itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context)!.suggestions,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: suggestions.length,
            itemBuilder: (context, index) => ColoredChipWrapper(
              child: itemBuilder(context, suggestions.elementAt(index)),
            ),
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 4.0),
          ),
        ),
      ],
    ).padded();
  }
}

// class SampleWidget extends StatefulWidget {
//   const SampleWidget({super.key});

//   @override
//   State<SampleWidget> createState() => _SampleWidgetState();
// }

// class _SampleWidgetState extends State<SampleWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<OptionsBloc, OptionsState>(
//       builder: (context, state) {
//         return OptionsFormField(
//           options: state.options,
//           onAddOption: (option) {
//             // This will call the repository and will cause a new state containing the new option to be emitted.
//             context.read<OptionsBloc>().addOption(option);
//           },
//         );
//       },
//     );
//   }
// }

// class OptionsFormField extends StatefulWidget {
//   final List<Option> options;
//   final void Function(Option option) onAddOption;

//   const OptionsFormField({
//     super.key,
//     required this.options,
//     required this.onAddOption,
//   });

//   @override
//   State<OptionsFormField> createState() => _OptionsFormFieldState();
// }

// class _OptionsFormFieldState extends State<OptionsFormField> {
//   final TextEditingController _controller;
//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       onTap: () async {
//         // User creates new option...
//         final Option option = await showOptionCreationForm();
//         widget.onAddOption(option);
//       },
//     );
//   }
// }
