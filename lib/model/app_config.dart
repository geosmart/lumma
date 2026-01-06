import 'enums.dart';
import 'sync_config.dart';
import 'mcp_config.dart';

class AppConfig {
  DiaryMode diaryMode;
  ThemeModeType theme;
  LanguageType language;
  SyncConfig sync;
  McpConfig mcp;

  AppConfig({
    this.diaryMode = DiaryMode.timeline,
    this.theme = ThemeModeType.dark,
    this.language = LanguageType.zh,
    SyncConfig? sync,
    McpConfig? mcp,
  }) : sync = sync ?? SyncConfig.defaultConfig(),
       mcp = mcp ?? McpConfig.defaultConfig();

  /// 创建默认配置
  factory AppConfig.defaultConfig() {
    // 创建默认同步配置
    final defaultSync = SyncConfig.defaultConfig();
    final defaultMcp = McpConfig.defaultConfig();

    return AppConfig(
      diaryMode: DiaryMode.timeline,
      theme: ThemeModeType.dark,
      language: LanguageType.zh,
      sync: defaultSync,
      mcp: defaultMcp,
    );
  }

  factory AppConfig.fromMap(Map map) => AppConfig(
    diaryMode: diaryModeFromString(map['diary_mode'] ?? 'timeline'),
    theme: themeModeTypeFromString(map['theme'] ?? 'light'),
    language: languageTypeFromString(map['language'] ?? 'zh'),
    sync: map['sync'] != null ? SyncConfig.fromMap(map['sync']) : SyncConfig.defaultConfig(),
    mcp: map['mcp'] != null ? McpConfig.fromMap(map['mcp']) : McpConfig.defaultConfig(),
  );

  Map<String, dynamic> toMap() => {
    'diary_mode': diaryModeToString(diaryMode),
    'theme': themeModeTypeToString(theme),
    'language': languageTypeToString(language),
    'sync': sync.toMap(),
    'mcp': mcp.toMap(),
  };
}
