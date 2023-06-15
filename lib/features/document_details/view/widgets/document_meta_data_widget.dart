import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/document_details/cubit/document_details_cubit.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/archive_serial_number_field.dart';
import 'package:paperless_mobile/features/document_details/view/widgets/details_item.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/format_helpers.dart';

class DocumentMetaDataWidget extends StatefulWidget {
  final DocumentModel document;
  final double itemSpacing;
  const DocumentMetaDataWidget({
    super.key,
    required this.document,
    required this.itemSpacing,
  });

  @override
  State<DocumentMetaDataWidget> createState() => _DocumentMetaDataWidgetState();
}

class _DocumentMetaDataWidgetState extends State<DocumentMetaDataWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentDetailsCubit, DocumentDetailsState>(
      builder: (context, state) {
        if (state.metaData == null) {
          return const SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildListDelegate(
            [
              ArchiveSerialNumberField(
                document: widget.document,
              ).paddedOnly(bottom: widget.itemSpacing),
              DetailsItem.text(
                DateFormat().format(widget.document.modified),
                context: context,
                label: S.of(context)!.modifiedAt,
              ).paddedOnly(bottom: widget.itemSpacing),
              DetailsItem.text(
                DateFormat().format(widget.document.added),
                context: context,
                label: S.of(context)!.addedAt,
              ).paddedOnly(bottom: widget.itemSpacing),
              DetailsItem.text(
                state.metaData!.mediaFilename,
                context: context,
                label: S.of(context)!.mediaFilename,
              ).paddedOnly(bottom: widget.itemSpacing),
              if (state.document.originalFileName != null)
                DetailsItem.text(
                  state.document.originalFileName!,
                  context: context,
                  label: S.of(context)!.originalMD5Checksum,
                ).paddedOnly(bottom: widget.itemSpacing),
              DetailsItem.text(
                state.metaData!.originalChecksum,
                context: context,
                label: S.of(context)!.originalMD5Checksum,
              ).paddedOnly(bottom: widget.itemSpacing),
              DetailsItem.text(
                formatBytes(state.metaData!.originalSize, 2),
                context: context,
                label: S.of(context)!.originalFileSize,
              ).paddedOnly(bottom: widget.itemSpacing),
              DetailsItem.text(
                state.metaData!.originalMimeType,
                context: context,
                label: S.of(context)!.originalMIMEType,
              ).paddedOnly(bottom: widget.itemSpacing),
            ],
          ),
        );
      },
    );
  }
}
