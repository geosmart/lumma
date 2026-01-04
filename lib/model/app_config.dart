import 'enums.dart';
import 'sync_config.dart';

class AppConfig {
  DiaryMode diaryMode;
  ThemeModeType theme;
  LanguageType language;
  SyncConfig sync;

  AppConfig({
    this.diaryMode = DiaryMode.timeline,
    this.theme = ThemeModeType.dark,
    this.language = LanguageType.zh,
    SyncConfig? sync,
  }) : sync = sync ?? SyncConfig.defaultConfig();

  /// 创建默认配置
  factory AppConfig.defaultConfig() {
    // 创建默认同步配置
    final defaultSync = SyncConfig.defaultConfig();

    return AppConfig(
      diaryMode: DiaryMode.timeline,
      theme: ThemeModeType.dark,
      language: LanguageType.zh,
      sync: defaultSync,
    );
  }

  factory AppConfig.fromMap(Map map) => AppConfig(
    diaryMode: diaryModeFromString(map['diary_mode'] ?? 'timeline'),
    theme: themeModeTypeFromString(map['theme'] ?? 'light'),
    language: languageTypeFromString(map['language'] ?? 'zh'),
    sync: map['sync'] != null ? SyncConfig.fromMap(map['sync']) : SyncConfig.defaultConfig(),
  );

  Map<String, dynamic> toMap() => {
    'diary_mode': diaryModeToString(diaryMode),
    'theme': themeModeTypeToString(theme),
    'language': languageTypeToString(language),
    'sync': sync.toMap(),
  };
}
