import 'package:bloc/bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/paged_documents_state.dart';

part 'similar_documents_state.dart';

class SimilarDocumentsCubit extends Cubit<SimilarDocumentsState>
    with DocumentPagingBlocMixin {
  final int documentId;

  @override
  final PaperlessDocumentsApi api;

  final LabelRepository _labelRepository;

  @override
  final DocumentChangedNotifier notifier;

  SimilarDocumentsCubit(
    this.api,
    this.notifier,
    this._labelRepository, {
    required this.documentId,
  }) : super(const SimilarDocumentsState(filter: DocumentFilter())) {
    notifier.addListener(
      this,
      onDeleted: remove,
      onUpdated: replace,
    );
    _labelRepository.addListener(
      this,
      onChanged: (labels) {
        emit(state.copyWith(
          correspondents: labels.correspondents,
          documentTypes: labels.documentTypes,
          tags: labels.tags,
          storagePaths: labels.storagePaths,
        ));
      },
    );
  }

  Future<void> initialize() async {
    if (!state.hasLoaded) {
      await updateFilter(
        filter: state.filter.copyWith(
          moreLike: () => documentId,
          sortField: SortField.score,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    notifier.removeListener(this);
    _labelRepository.removeListener(this);
    return super.close();
  }

  @override
  Future<void> onFilterUpdated(DocumentFilter filter) async {}
}
