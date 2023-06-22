import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_api/src/models/query_parameters/date_range_queries/date_range_query.dart';
import 'package:paperless_api/src/models/query_parameters/date_range_queries/date_range_query_field.dart';

part 'document_filter.g.dart';

@DateRangeQueryJsonConverter()
@JsonSerializable(explicitToJson: true)
@HiveType(typeId: PaperlessApiHiveTypeIds.documentFilter)
class DocumentFilter extends Equatable {
  static const DocumentFilter initial = DocumentFilter();

  static const DocumentFilter latestDocument = DocumentFilter(
    sortField: SortField.added,
    sortOrder: SortOrder.descending,
    pageSize: 1,
    page: 1,
  );

  @HiveField(0)
  final int pageSize;

  @HiveField(1)
  final int page;

  @HiveField(2)
  final IdQueryParameter documentType;

  @HiveField(3)
  final IdQueryParameter correspondent;

  @HiveField(4)
  final IdQueryParameter storagePath;

  @HiveField(5)
  final IdQueryParameter asnQuery;

  @HiveField(6)
  final TagsQuery tags;

  @HiveField(7)
  final SortField? sortField;

  @HiveField(8)
  final SortOrder sortOrder;

  @HiveField(9)
  final DateRangeQuery created;

  @HiveField(10)
  final DateRangeQuery added;

  @HiveField(11)
  final DateRangeQuery modified;

  @HiveField(12)
  final TextQuery query;

  @HiveField(13)
  final int? moreLike;

  const DocumentFilter({
    this.documentType = const IdQueryParameter.unset(),
    this.correspondent = const IdQueryParameter.unset(),
    this.storagePath = const IdQueryParameter.unset(),
    this.asnQuery = const IdQueryParameter.unset(),
    this.tags = const TagsQuery.ids(),
    this.sortField = SortField.created,
    this.sortOrder = SortOrder.descending,
    this.page = 1,
    this.pageSize = 25,
    this.query = const TextQuery(),
    this.added = const UnsetDateRangeQuery(),
    this.created = const UnsetDateRangeQuery(),
    this.modified = const UnsetDateRangeQuery(),
    this.moreLike,
  });

  bool get forceExtendedQuery {
    return added is RelativeDateRangeQuery ||
        created is RelativeDateRangeQuery ||
        modified is RelativeDateRangeQuery;
  }

  Map<String, dynamic> toQueryParameters() {
    List<MapEntry<String, dynamic>> params = [
      MapEntry('page', '$page'),
      MapEntry('page_size', '$pageSize'),
      ...documentType.toQueryParameter('document_type').entries,
      ...correspondent.toQueryParameter('correspondent').entries,
      ...storagePath.toQueryParameter('storage_path').entries,
      ...asnQuery.toQueryParameter('archive_serial_number').entries,
      ...tags.toQueryParameter().entries,
      ...added.toQueryParameter(DateRangeQueryField.added).entries,
      ...created.toQueryParameter(DateRangeQueryField.created).entries,
      ...modified.toQueryParameter(DateRangeQueryField.modified).entries,
      ...query.toQueryParameter().entries,
    ];
    if (sortField != null) {
      params.add(
        MapEntry(
          'ordering',
          '${sortOrder.queryString}${sortField!.queryString}',
        ),
      );
    }

    if (moreLike != null) {
      params.add(MapEntry('more_like_id', moreLike.toString()));
    }
    // Reverse ordering can also be encoded using &reverse=1
    // Merge query params
    final queryParams = groupBy(params, (e) => e.key).map(
      (key, entries) => MapEntry(
        key,
        entries.length == 1
            ? entries.first.value
            : entries.map((e) => e.value).join(","),
      ),
    );
    return queryParams;
  }

  @override
  String toString() => toQueryParameters().toString();

  DocumentFilter copyWith({
    int? pageSize,
    int? page,
    IdQueryParameter? documentType,
    IdQueryParameter? correspondent,
    IdQueryParameter? storagePath,
    IdQueryParameter? asnQuery,
    TagsQuery? tags,
    SortField? sortField,
    SortOrder? sortOrder,
    DateRangeQuery? added,
    DateRangeQuery? created,
    DateRangeQuery? modified,
    TextQuery? query,
    int? Function()? moreLike,
  }) {
    final newFilter = DocumentFilter(
      pageSize: pageSize ?? this.pageSize,
      page: page ?? this.page,
      documentType: documentType ?? this.documentType,
      correspondent: correspondent ?? this.correspondent,
      storagePath: storagePath ?? this.storagePath,
      tags: tags ?? this.tags,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      asnQuery: asnQuery ?? this.asnQuery,
      query: query ?? this.query,
      added: added ?? this.added,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      moreLike: moreLike != null ? moreLike.call() : this.moreLike,
    );
    if (query?.queryType != QueryType.extended &&
        newFilter.forceExtendedQuery) {
      //Prevents infinite recursion
      return newFilter.copyWith(
        query: newFilter.query.copyWith(queryType: QueryType.extended),
      );
    }
    return newFilter;
  }

  ///
  /// Checks whether the properties of [document] match the current filter criteria.
  ///
  bool matches(DocumentModel document) {
    return correspondent.matches(document.correspondent) &&
        documentType.matches(document.documentType) &&
        storagePath.matches(document.storagePath) &&
        tags.matches(document.tags) &&
        created.matches(document.created) &&
        added.matches(document.added) &&
        modified.matches(document.modified) &&
        query.matches(
          title: document.title,
          content: document.content,
          asn: document.archiveSerialNumber,
        );
  }

  int get appliedFiltersCount => [
        documentType.maybeWhen(
          unset: () => 0,
          orElse: () => 1,
        ),
        correspondent.maybeWhen(
          unset: () => 0,
          orElse: () => 1,
        ),
        storagePath.maybeWhen(
          unset: () => 0,
          orElse: () => 1,
        ),
        tags.maybeWhen(
          ids: (include, exclude) => include.length + exclude.length,
          anyAssigned: (tagIds) => tagIds.length,
          notAssigned: () => 1,
          orElse: () => 0,
        ),
        switch (added) {
          RelativeDateRangeQuery() => 1,
          AbsoluteDateRangeQuery() => 1,
          UnsetDateRangeQuery() => 0,
        },
        switch (created) {
          RelativeDateRangeQuery() => 1,
          AbsoluteDateRangeQuery() => 1,
          UnsetDateRangeQuery() => 0,
        },
        switch (modified) {
          RelativeDateRangeQuery() => 1,
          AbsoluteDateRangeQuery() => 1,
          UnsetDateRangeQuery() => 0,
        },
        asnQuery.maybeWhen(
          unset: () => 0,
          orElse: () => 1,
        ),
        (query.queryText?.isNotEmpty ?? false) ? 1 : 0,
      ].fold(0, (previousValue, element) => previousValue + element);

  @override
  List<Object?> get props => [
        pageSize,
        page,
        documentType,
        correspondent,
        storagePath,
        asnQuery,
        tags,
        sortField,
        sortOrder,
        added,
        created,
        modified,
        query,
      ];

  factory DocumentFilter.fromJson(Map<String, dynamic> json) =>
      _$DocumentFilterFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentFilterToJson(this);
}
