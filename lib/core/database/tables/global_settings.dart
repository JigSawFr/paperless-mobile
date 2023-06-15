import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:paperless_mobile/core/config/hive/hive_config.dart';
import 'package:paperless_mobile/features/settings/model/color_scheme_option.dart';
import 'package:paperless_mobile/features/settings/model/file_download_type.dart';

part 'global_settings.g.dart';

@HiveType(typeId: HiveTypeIds.globalSettings)
class GlobalSettings with HiveObjectMixin {
  @HiveField(0)
  String preferredLocaleSubtag;

  @HiveField(1)
  ThemeMode preferredThemeMode;

  @HiveField(2)
  ColorSchemeOption preferredColorSchemeOption;

  @HiveField(3)
  bool showOnboarding;

  @HiveField(4)
  String? currentLoggedInUser;

  @HiveField(5)
  FileDownloadType defaultDownloadType;

  @HiveField(6)
  FileDownloadType defaultShareType;

  @HiveField(7, defaultValue: false)
  bool enforceSinglePagePdfUpload;

  GlobalSettings({
    required this.preferredLocaleSubtag,
    this.preferredThemeMode = ThemeMode.system,
    this.preferredColorSchemeOption = ColorSchemeOption.classic,
    this.showOnboarding = true,
    this.currentLoggedInUser,
    this.defaultDownloadType = FileDownloadType.alwaysAsk,
    this.defaultShareType = FileDownloadType.alwaysAsk,
    this.enforceSinglePagePdfUpload = false,
  });
}
