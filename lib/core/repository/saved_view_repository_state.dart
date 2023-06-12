part of 'saved_view_repository.dart';

@freezed
class SavedViewRepositoryState with _$SavedViewRepositoryState {
  const factory SavedViewRepositoryState.initial({
    @Default({}) Map<int, SavedView> savedViews,
  }) = _Initial;
  const factory SavedViewRepositoryState.loading({
    @Default({}) Map<int, SavedView> savedViews,
  }) = _Loading;
  const factory SavedViewRepositoryState.loaded({
    @Default({}) Map<int, SavedView> savedViews,
  }) = _Loaded;
  const factory SavedViewRepositoryState.error({
    @Default({}) Map<int, SavedView> savedViews,
  }) = _Error;

  factory SavedViewRepositoryState.fromJson(Map<String, dynamic> json) =>
      _$SavedViewRepositoryStateFromJson(json);
}
