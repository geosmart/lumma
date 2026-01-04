import 'package:flutter/widgets.dart';
import '../generated/l10n/app_localizations.dart';

enum DiaryMode { chat, timeline }

String diaryModeToString(DiaryMode mode) {
  switch (mode) {
    case DiaryMode.chat:
      return 'chat';
    case DiaryMode.timeline:
      return 'timeline';
  }
}

DiaryMode diaryModeFromString(String value) {
  switch (value) {
    case 'chat':
      return DiaryMode.chat;
    case 'timeline':
      return DiaryMode.timeline;
    default:
      return DiaryMode.timeline;
  }
}

enum ThemeModeType { light, dark }

String themeModeTypeToString(ThemeModeType mode) {
  switch (mode) {
    case ThemeModeType.light:
      return 'light';
    case ThemeModeType.dark:
      return 'dark';
  }
}

ThemeModeType themeModeTypeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeModeType.light;
    case 'dark':
      return ThemeModeType.dark;
    default:
      return ThemeModeType.dark;
  }
}

// 同步模式枚举
enum SyncMode { obsidian, webdav }

// 获取同步模式显示名称
String syncModeToDisplayName(SyncMode mode) {
  switch (mode) {
    case SyncMode.obsidian:
      return 'Obsidian';
    case SyncMode.webdav:
      return 'WebDAV';
  }
}

// 将同步模式枚举转换为字符串
String syncModeToString(SyncMode mode) {
  switch (mode) {
    case SyncMode.obsidian:
      return 'obsidian';
    case SyncMode.webdav:
      return 'webdav';
  }
}

// 根据字符串获取同步模式枚举
SyncMode syncModeFromString(String value) {
  switch (value) {
    case 'obsidian':
      return SyncMode.obsidian;
    case 'webdav':
      return SyncMode.webdav;
    default:
      return SyncMode.obsidian;
  }
}

// 语言枚举
enum LanguageType { zh, en }

// 将语言枚举转换为字符串
String languageTypeToString(LanguageType language) {
  switch (language) {
    case LanguageType.zh:
      return 'zh';
    case LanguageType.en:
      return 'en';
  }
}

// 根据字符串获取语言枚举
LanguageType languageTypeFromString(String value) {
  switch (value) {
    case 'zh':
      return LanguageType.zh;
    case 'en':
      return LanguageType.en;
    default:
      return LanguageType.zh;
  }
}
