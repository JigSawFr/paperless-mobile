import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/database/tables/local_user_app_state.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/paged_documents_state.dart';
import 'package:paperless_mobile/features/paged_document_view/cubit/document_paging_bloc_mixin.dart';
import 'package:paperless_mobile/features/settings/model/view_type.dart';

part 'saved_view_details_state.dart';

class SavedViewDetailsCubit extends Cubit<SavedViewDetailsState>
    with DocumentPagingBlocMixin {
  @override
  final PaperlessDocumentsApi api;

  final LabelRepository _labelRepository;

  @override
  final DocumentChangedNotifier notifier;

  final SavedView savedView;

  final LocalUserAppState _userState;

  SavedViewDetailsCubit(
    this.api,
    this.notifier,
    this._labelRepository,
    this._userState, {
    required this.savedView,
  }) : super(
          SavedViewDetailsState(
            correspondents: _labelRepository.state.correspondents,
            documentTypes: _labelRepository.state.documentTypes,
            tags: _labelRepository.state.tags,
            storagePaths: _labelRepository.state.storagePaths,
            viewType: _userState.savedViewsViewType,
          ),
        ) {
    notifier.addListener(
      this,
      onDeleted: remove,
      onUpdated: replace,
    );
    _labelRepository.addListener(
      this,
      onChanged: (labels) {
        if (!isClosed) {
          emit(state.copyWith(
            correspondents: labels.correspondents,
            documentTypes: labels.documentTypes,
            tags: labels.tags,
            storagePaths: labels.storagePaths,
          ));
        }
      },
    );
    updateFilter(filter: savedView.toDocumentFilter());
  }

  void setViewType(ViewType viewType) {
    emit(state.copyWith(viewType: viewType));
    _userState
      ..savedViewsViewType = viewType
      ..save();
  }

  @override
  Future<void> onFilterUpdated(DocumentFilter filter) async {}
}
