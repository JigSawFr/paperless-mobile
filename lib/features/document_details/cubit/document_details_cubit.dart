import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/notifier/document_changed_notifier.dart';
import 'package:paperless_mobile/core/repository/label_repository.dart';
import 'package:paperless_mobile/core/service/file_description.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

part 'document_details_cubit.freezed.dart';
part 'document_details_state.dart';

class DocumentDetailsCubit extends Cubit<DocumentDetailsState> {
  final PaperlessDocumentsApi _api;
  final DocumentChangedNotifier _notifier;
  final LocalNotificationService _notificationService;
  final LabelRepository _labelRepository;

  DocumentDetailsCubit(
    this._api,
    this._labelRepository,
    this._notifier,
    this._notificationService, {
    required DocumentModel initialDocument,
  }) : super(DocumentDetailsState(
          document: initialDocument,
        )) {
    _notifier.addListener(this, onUpdated: replace);
    _labelRepository.addListener(
      this,
      onChanged: (labels) => emit(
        state.copyWith(
          correspondents: labels.correspondents,
          documentTypes: labels.documentTypes,
          tags: labels.tags,
          storagePaths: labels.storagePaths,
        ),
      ),
    );
    loadSuggestions();
    loadMetaData();
  }

  Future<void> delete(DocumentModel document) async {
    await _api.delete(document);
    _notifier.notifyDeleted(document);
  }

  Future<void> loadSuggestions() async {
    final suggestions = await _api.findSuggestions(state.document);
    if (!isClosed) {
      emit(state.copyWith(suggestions: suggestions));
    }
  }

  Future<void> loadMetaData() async {
    final metaData = await _api.getMetaData(state.document);
    if (!isClosed) {
      emit(state.copyWith(metaData: metaData));
    }
  }

  Future<void> loadFullContent() async {
    final doc = await _api.find(state.document.id);
    if (doc == null) {
      return;
    }
    emit(state.copyWith(
      isFullContentLoaded: true,
      fullContent: doc.content,
    ));
  }

  Future<void> assignAsn(
    DocumentModel document, {
    int? asn,
    bool autoAssign = false,
  }) async {
    if (!autoAssign) {
      final updatedDocument = await _api.update(
        document.copyWith(archiveSerialNumber: () => asn),
      );
      _notifier.notifyUpdated(updatedDocument);
    } else {
      final int autoAsn = await _api.findNextAsn();
      final updatedDocument = await _api
          .update(document.copyWith(archiveSerialNumber: () => autoAsn));
      _notifier.notifyUpdated(updatedDocument);
    }
  }

  Future<ResultType> openDocumentInSystemViewer() async {
    final cacheDir = await FileService.temporaryDirectory;
    //TODO: Why is this cleared here?
    await FileService.clearDirectoryContent(PaperlessDirectoryType.temporary);
    if (state.metaData == null) {
      await loadMetaData();
    }
    final desc = FileDescription.fromPath(
        state.metaData!.mediaFilename.replaceAll("/", " "));

    final fileName = "${desc.filename}.pdf";
    final file = File("${cacheDir.path}/$fileName");

    if (!file.existsSync()) {
      file.createSync();
      await _api.downloadToFile(
        state.document,
        file.path,
      );
    }
    return OpenFilex.open(
      file.path,
      type: "application/pdf",
    ).then((value) => value.type);
  }

  void replace(DocumentModel document) {
    emit(state.copyWith(document: document));
  }

  Future<void> downloadDocument({
    bool downloadOriginal = false,
    required String locale,
  }) async {
    if (state.metaData == null) {
      await loadMetaData();
    }
    String filePath = _buildDownloadFilePath(
      downloadOriginal,
      await FileService.downloadsDirectory,
    );
    final desc = FileDescription.fromPath(
      state.metaData!.mediaFilename
          .replaceAll("/", " "), // Flatten directory structure
    );
    if (!File(filePath).existsSync()) {
      File(filePath).createSync();
    } else {
      return _notificationService.notifyFileDownload(
        document: state.document,
        filename: "${desc.filename}.${desc.extension}",
        filePath: filePath,
        finished: true,
        locale: locale,
      );
    }

    await _notificationService.notifyFileDownload(
      document: state.document,
      filename: "${desc.filename}.${desc.extension}",
      filePath: filePath,
      finished: false,
      locale: locale,
    );

    await _api.downloadToFile(
      state.document,
      filePath,
      original: downloadOriginal,
    );
    await _notificationService.notifyFileDownload(
      document: state.document,
      filename: "${desc.filename}.${desc.extension}",
      filePath: filePath,
      finished: true,
      locale: locale,
    );
    debugPrint("Downloaded file to $filePath");
  }

  Future<void> shareDocument({bool shareOriginal = false}) async {
    if (state.metaData == null) {
      await loadMetaData();
    }
    String filePath = _buildDownloadFilePath(
      shareOriginal,
      await FileService.temporaryDirectory,
    );
    await _api.downloadToFile(
      state.document,
      filePath,
      original: shareOriginal,
    );
    Share.shareXFiles(
      [
        XFile(
          filePath,
          name: state.document.originalFileName,
          mimeType: "application/pdf",
          lastModified: state.document.modified,
        ),
      ],
      subject: state.document.title,
    );
  }

  Future<void> printDocument() async {
    if (state.metaData == null) {
      await loadMetaData();
    }
    final filePath =
        _buildDownloadFilePath(false, await FileService.temporaryDirectory);
    await _api.downloadToFile(
      state.document,
      filePath,
      original: false,
    );
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception("An error occurred while downloading the document.");
    }
    Printing.layoutPdf(
      name: state.document.title,
      onLayout: (format) => file.readAsBytesSync(),
    );
  }

  String _buildDownloadFilePath(bool original, Directory dir) {
    final description = FileDescription.fromPath(
      state.metaData!.mediaFilename
          .replaceAll("/", " "), // Flatten directory structure
    );
    final extension = original ? description.extension : 'pdf';
    return "${dir.path}/${description.filename}.$extension";
  }

  @override
  Future<void> close() async {
    _labelRepository.removeListener(this);
    _notifier.removeListener(this);
    await super.close();
  }
}
