import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/documents/view/widgets/document_preview.dart';
import 'package:paperless_mobile/features/documents/view/widgets/items/document_item.dart';
import 'package:paperless_mobile/features/labels/correspondent/view/widgets/correspondent_widget.dart';
import 'package:paperless_mobile/features/labels/document_type/view/widgets/document_type_widget.dart';
import 'package:paperless_mobile/features/labels/tags/view/widgets/tags_widget.dart';
import 'package:provider/provider.dart';

class DocumentGridItem extends DocumentItem {
  const DocumentGridItem({
    super.key,
    required super.document,
    required super.isSelected,
    required super.isSelectionActive,
    required super.isLabelClickable,
    super.onCorrespondentSelected,
    super.onDocumentTypeSelected,
    super.onSelected,
    super.onStoragePathSelected,
    super.onTagSelected,
    super.onTap,
    required super.enableHeroAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 1.0,
        color: isSelected
            ? Theme.of(context).colorScheme.inversePrimary
            : Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _onTap,
          onLongPress: onSelected != null ? () => onSelected!(document) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DocumentPreview(
                        document: document,
                        borderRadius: 12.0,
                        enableHero: enableHeroAnimation,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: SizedBox(
                        height: 48,
                        child: NotificationListener<ScrollNotification>(
                          // Prevents ancestor notification listeners to be notified when this widget scrolls
                          onNotification: (notification) => true,
                          child: CustomScrollView(
                            scrollDirection: Axis.horizontal,
                            slivers: [
                              const SliverToBoxAdapter(
                                child: SizedBox(width: 8),
                              ),
                              TagsWidget.sliver(
                                tags: document.tags
                                    .map((e) => context
                                        .watch<LabelRepository>()
                                        .state
                                        .tags[e]!)
                                    .toList(),
                                onTagSelected: onTagSelected,
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(width: 8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CorrespondentWidget(
                        correspondent: context
                            .watch<LabelRepository>()
                            .state
                            .correspondents[document.correspondent],
                        onSelected: onCorrespondentSelected,
                      ),
                      DocumentTypeWidget(
                        documentType: context
                            .watch<LabelRepository>()
                            .state
                            .documentTypes[document.documentType],
                        onSelected: onDocumentTypeSelected,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          document.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat.yMMMd().format(document.created),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap() {
    if (isSelectionActive || isSelected) {
      onSelected?.call(document);
    } else {
      onTap?.call(document);
    }
  }
}
