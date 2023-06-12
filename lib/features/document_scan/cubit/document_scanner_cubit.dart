import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paperless_api/paperless_api.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/features/notifications/services/local_notification_service.dart';

class DocumentScannerCubit extends Cubit<List<File>> {
  final LocalNotificationService _notificationService;

  DocumentScannerCubit(this._notificationService) : super(const []);

  void addScan(File file) => emit([...state, file]);

  void removeScan(int fileIndex) {
    try {
      state[fileIndex].deleteSync();
      final scans = [...state];
      scans.removeAt(fileIndex);
      emit(scans);
    } catch (_) {
      throw const PaperlessServerException(ErrorCode.scanRemoveFailed);
    }
  }

  void reset() {
    try {
      for (final doc in state) {
        doc.deleteSync();
        if (kDebugMode) {
          log('[ScannerCubit]: Removed ${doc.path}');
        }
      }
      imageCache.clear();
      emit([]);
    } catch (_) {
      throw const PaperlessServerException(ErrorCode.scanRemoveFailed);
    }
  }

  Future<void> saveToFile(
    Uint8List bytes,
    String fileName,
    String locale,
  ) async {
    var file = await FileService.saveToFile(bytes, fileName);
    _notificationService.notifyFileSaved(
      filename: fileName,
      filePath: file.path,
      finished: true,
      locale: locale,
    );
  }
}
