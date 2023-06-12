import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/navigation/push_routes.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/cubit/documents_cubit.dart';
import 'package:paperless_mobile/features/documents/view/widgets/selection/bulk_delete_confirmation_dialog.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';

class DocumentSelectionSliverAppBar extends StatelessWidget {
  final DocumentsState state;
  const DocumentSelectionSliverAppBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      stretch: false,
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      title: Text(
        S.of(context)!.countSelected(state.selection.length),
      ),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.read<DocumentsCubit>().resetSelection(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) =>
                      BulkDeleteConfirmationDialog(state: state),
                ) ??
                false;
            if (shouldDelete) {
              try {
                await context
                    .read<DocumentsCubit>()
                    .bulkDelete(state.selection);
                showSnackBar(
                  context,
                  S.of(context)!.documentsSuccessfullyDeleted,
                );
                context.read<DocumentsCubit>().resetSelection();
              } on PaperlessServerException catch (error, stackTrace) {
                showErrorMessage(context, error, stackTrace);
              }
            }
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(kTextTabBarHeight),
        child: SizedBox(
          height: kTextTabBarHeight,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ActionChip(
                label: Text(S.of(context)!.correspondent),
                avatar: const Icon(Icons.edit),
                onPressed: () {
                  pushBulkEditCorrespondentRoute(context,
                      selection: state.selection);
                },
              ).paddedOnly(left: 8, right: 4),
              ActionChip(
                label: Text(S.of(context)!.documentType),
                avatar: const Icon(Icons.edit),
                onPressed: () async {
                  pushBulkEditDocumentTypeRoute(context,
                      selection: state.selection);
                },
              ).paddedOnly(left: 8, right: 4),
              ActionChip(
                label: Text(S.of(context)!.storagePath),
                avatar: const Icon(Icons.edit),
                onPressed: () async {
                  pushBulkEditStoragePathRoute(context,
                      selection: state.selection);
                },
              ).paddedOnly(left: 8, right: 4),
              _buildBulkEditTagsChip(context).paddedOnly(left: 4, right: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulkEditTagsChip(BuildContext context) {
    return ActionChip(
      label: Text(S.of(context)!.tags),
      avatar: const Icon(Icons.edit),
      onPressed: () {
        pushBulkEditTagsRoute(context, selection: state.selection);
      },
    );
  }
}
