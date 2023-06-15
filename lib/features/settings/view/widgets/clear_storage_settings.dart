import 'dart:io';

import 'package:flutter/material.dart';
import 'package:paperless_mobile/core/service/file_service.dart';
import 'package:paperless_mobile/generated/l10n/app_localizations.dart';
import 'package:paperless_mobile/helpers/format_helpers.dart';
import 'package:paperless_mobile/helpers/message_helpers.dart';

class ClearCacheSetting extends StatefulWidget {
  const ClearCacheSetting({super.key});

  @override
  State<ClearCacheSetting> createState() => _ClearCacheSettingState();
}

class _ClearCacheSettingState extends State<ClearCacheSetting> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(S.of(context)!.clearCache),
      subtitle: FutureBuilder<String>(
        future: FileService.temporaryDirectory.then(_dirSize),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Text(S.of(context)!.calculatingDots);
          }
          return Text(S.of(context)!.freeBytes(snapshot.data!));
        },
      ),
      onTap: () async {
        final dir = await FileService.temporaryDirectory;
        final deletedSize = await _dirSize(dir);
        await dir.delete(recursive: true);
        showSnackBar(
          context,
          S.of(context)!.freedDiskSpace(deletedSize),
        );
      },
    );
  }
}

Future<String> _dirSize(Directory dir) async {
  int totalSize = 0;
  try {
    if (await dir.exists()) {
      dir
          .listSync(recursive: true, followLinks: false)
          .forEach((FileSystemEntity entity) async {
        if (entity is File) {
          totalSize += (await entity.length());
        }
      });
    }
  } catch (error) {
    debugPrint(error.toString());
  }

  return formatBytes(totalSize, 0);
}
