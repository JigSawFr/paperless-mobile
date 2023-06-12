import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/repository/persistent_repository.dart';

part 'saved_view_repository_state.dart';
part 'saved_view_repository.g.dart';
part 'saved_view_repository.freezed.dart';

class SavedViewRepository
    extends PersistentRepository<SavedViewRepositoryState> {
  final PaperlessSavedViewsApi _api;
  final Completer _initialized = Completer();

  SavedViewRepository(this._api)
      : super(const SavedViewRepositoryState.initial());

  Future<void> initialize() async {
    try {
      await findAll();
      _initialized.complete();
    } catch (e) {
      _initialized.completeError(e);
      emit(const SavedViewRepositoryState.error());
    }
  }

  Future<SavedView> create(SavedView object) async {
    await _initialized.future;
    final created = await _api.save(object);
    final updatedState = {...state.savedViews}
      ..putIfAbsent(created.id!, () => created);
    emit(SavedViewRepositoryState.loaded(savedViews: updatedState));
    return created;
  }

  Future<int> delete(SavedView view) async {
    await _initialized.future;
    await _api.delete(view);
    final updatedState = {...state.savedViews}..remove(view.id);
    emit(SavedViewRepositoryState.loaded(savedViews: updatedState));
    return view.id!;
  }

  Future<SavedView?> find(int id) async {
    await _initialized.future;
    final found = await _api.find(id);
    if (found != null) {
      final updatedState = {...state.savedViews}
        ..update(id, (_) => found, ifAbsent: () => found);
      emit(SavedViewRepositoryState.loaded(savedViews: updatedState));
    }
    return found;
  }

  Future<Iterable<SavedView>> findAll([Iterable<int>? ids]) async {
    final found = await _api.findAll(ids);
    final updatedState = {
      ...state.savedViews,
      ...{for (final view in found) view.id!: view},
    };
    emit(SavedViewRepositoryState.loaded(savedViews: updatedState));
    return found;
  }

  @override
  Future<void> clear() async {
    await _initialized.future;
    await super.clear();
    emit(const SavedViewRepositoryState.initial());
  }

  @override
  SavedViewRepositoryState? fromJson(Map<String, dynamic> json) {
    return SavedViewRepositoryState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(SavedViewRepositoryState state) {
    return state.toJson();
  }
}
