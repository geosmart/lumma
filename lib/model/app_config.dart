import 'enums.dart';
import 'llm_config.dart';
import 'prompt_config.dart';
import 'sync_config.dart';

class AppConfig {
  DiaryMode diaryMode;
  ThemeModeType theme;
  LanguageType language;
  List<LLMConfig> model;
  List<PromptConfig> prompt;
  SyncConfig sync;
  List<String> categoryList;

  static const List<String> defaultCategoryList = [
    '想法', '观察', '工作', '生活', '育儿', '学习', '健康', '情感'
  ];

  AppConfig({
    this.diaryMode = DiaryMode.timeline,
    this.model = const [],
    List<PromptConfig>? prompt,
    this.theme = ThemeModeType.dark,
    this.language = LanguageType.zh,
    SyncConfig? sync,
    List<String>? categoryList,
  }) : prompt = prompt ?? const [],
       sync = sync ?? SyncConfig.defaultConfig(),
       categoryList = categoryList ?? const [];

  /// 创建默认配置
  factory AppConfig.defaultConfig() {
    // 创建默认提示词配置
    final defaultPrompts = [PromptConfig.chatDefault(), PromptConfig.summaryDefault()];

    // 创建默认LLM配置
    final defaultModels = [LLMConfig.openRouterDefault(), LLMConfig.deepSeekDefault()];

    // 创建默认同步配置
    final defaultSync = SyncConfig.defaultConfig();

    return AppConfig(
      diaryMode: DiaryMode.timeline,
      theme: ThemeModeType.dark,
      language: LanguageType.zh,
      model: defaultModels,
      prompt: defaultPrompts,
      sync: defaultSync,
      categoryList: const [],
    );
  }

  List<String> getCategoryList() {
    return categoryList.isNotEmpty ? categoryList : List<String>.from(defaultCategoryList);
  }

  factory AppConfig.fromMap(Map map) => AppConfig(
    diaryMode: diaryModeFromString(map['diary_mode'] ?? 'timeline'),
    model: (map['model'] as List? ?? []).map((e) => LLMConfig.fromMap(e)).toList(),
    prompt: (map['prompt'] as List? ?? []).map((e) => PromptConfig.fromMap(e)).toList(),
    theme: themeModeTypeFromString(map['theme'] ?? 'light'),
    language: languageTypeFromString(map['language'] ?? 'zh'),
    sync: map['sync'] != null ? SyncConfig.fromMap(map['sync']) : SyncConfig.defaultConfig(),
    categoryList: (map['category_list'] as List? ?? []).map((e) => e.toString()).toList(),
  );
  Map<String, dynamic> toMap() => {
    'diary_mode': diaryModeToString(diaryMode),
    'model': model.map((e) => e.toMap()).toList(),
    'prompt': prompt.map((e) => e.toMap()).toList(),
    'theme': themeModeTypeToString(theme),
    'language': languageTypeToString(language),
    'sync': sync.toMap(),
    'category_list': categoryList,
  };
}
