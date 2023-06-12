import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as cm;
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/helpers/format_helpers.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';
import 'package:provider/provider.dart';

class ClearCacheSetting extends StatelessWidget {
  const ClearCacheSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Clear downloaded files"), //TODO: INTL
      subtitle: const Text(
          "Deletes all files downloaded from this app."), //TODO: INTL
      onTap: () async {
        final dir = await FileService.downloadsDirectory;
        final deletedSize = _dirSize(dir);
        await dir.delete(recursive: true);
        // await context.read<cm.CacheManager>().emptyCache();
        showSnackBar(
          context,
          "Downloads successfully cleared, removed $deletedSize.",
        );
      },
    );
  }
}

class ClearDownloadsSetting extends StatelessWidget {
  const ClearDownloadsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Clear downloads"), //TODO: INTL
      subtitle: const Text(
          "Remove downloaded files, scans and clear the cache's content"), //TODO: INTL
      onTap: () {
        FileService.documentsDirectory;
        FileService.downloadsDirectory;
        context.read<cm.CacheManager>().emptyCache();
        FileService.clearUserData();
        //TODO: Show notification about clearing (include size?)
      },
    );
  }
}

String _dirSize(Directory dir) {
  int totalSize = 0;
  try {
    if (dir.existsSync()) {
      dir
          .listSync(recursive: true, followLinks: false)
          .forEach((FileSystemEntity entity) {
        if (entity is File) {
          totalSize += entity.lengthSync();
        }
      });
    }
  } catch (e) {
    print(e.toString());
  }

  return formatBytes(totalSize, 2);
}
