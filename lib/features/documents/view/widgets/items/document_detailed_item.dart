import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/extensions/flutter_extensions.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_item.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/document_type/view/widgets/document_type_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:provider/provider.dart';

class DocumentDetailedItem extends DocumentItem {
  final String? highlights;
  const DocumentDetailedItem({
    super.key,
    this.highlights,
    required super.document,
    required super.isSelected,
    required super.isSelectionActive,
    required super.isLabelClickable,
    required super.enableHeroAnimation,
    super.onCorrespondentSelected,
    super.onDocumentTypeSelected,
    super.onSelected,
    super.onStoragePathSelected,
    super.onTagSelected,
    super.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final insets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).viewPadding;
    final availableHeight = size.height -
        insets.top -
        insets.bottom -
        padding.top -
        padding.bottom -
        kBottomNavigationBarHeight -
        kToolbarHeight;
    final maxHeight = highlights != null
        ? min(600.0, availableHeight)
        : min(500.0, availableHeight);
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.inversePrimary : null,
      child: InkWell(
        enableFeedback: true,
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelectionActive) {
            onSelected?.call(document);
          } else {
            onTap?.call(document);
          }
        },
        onLongPress: () {
          onSelected?.call(document);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints.tightFor(
                width: double.infinity,
                height: maxHeight / 2,
              ),
              child: DocumentPreview(
                document: document,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMMd().format(document.created),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.apply(color: Theme.of(context).hintColor),
                ),
                if (document.archiveSerialNumber != null)
                  Row(
                    children: [
                      Text(
                        '#${document.archiveSerialNumber}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.apply(color: Theme.of(context).hintColor),
                      ),
                    ],
                  ),
              ],
            ).paddedLTRB(8, 8, 8, 4),
            Text(
              document.title,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ).paddedLTRB(8, 0, 8, 4),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                ).paddedOnly(right: 4.0),
                CorrespondentWidget(
                  onSelected: onCorrespondentSelected,
                  textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  correspondent: context
                      .watch<LabelRepository>()
                      .state
                      .correspondents[document.correspondent],
                ),
              ],
            ).paddedLTRB(8, 0, 8, 4),
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 16,
                ).paddedOnly(right: 4.0),
                DocumentTypeWidget(
                  onSelected: onDocumentTypeSelected,
                  textStyle: Theme.of(context).textTheme.titleSmall?.apply(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  documentType: context
                      .watch<LabelRepository>()
                      .state
                      .documentTypes[document.documentType],
                ),
              ],
            ).paddedLTRB(8, 0, 8, 4),
            TagsWidget(
              isMultiLine: false,
              tags: document.tags
                  .map((e) => context.watch<LabelRepository>().state.tags[e]!)
                  .toList(),
            ).padded(),
            if (highlights != null)
              Html(
                data: '<p>${highlights!}</p>',
                style: {
                  "span": Style(
                    backgroundColor: Colors.yellow,
                    color: Colors.black,
                  ),
                  "p": Style(
                    maxLines: 3,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                },
              ).padded(),
          ],
        ),
      ),
    ).padded();
  }
}
