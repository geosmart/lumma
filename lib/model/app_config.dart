import 'enums.dart';
import 'llm_config.dart';
import 'prompt_config.dart';
import 'sync_config.dart';

class AppConfig {
  DiaryMode diaryMode;
  ThemeModeType theme;
  List<LLMConfig> model;
  List<PromptConfig> prompt;
  List<SyncConfig> sync;
  List<String> qaQuestions;

  AppConfig({
    this.diaryMode = DiaryMode.qa,
    this.model = const [],
    List<PromptConfig>? prompt,
    this.theme = ThemeModeType.light,
    List<SyncConfig>? sync,
    List<String>? qaQuestions,
  })  : prompt = prompt ?? const [],
        sync = sync ?? const [],
        qaQuestions = qaQuestions ?? const [];

  /// 创建默认配置
  factory AppConfig.defaultConfig() {
    // 创建默认提示词配置
    final defaultPrompts = [
      PromptConfig.qaDefault(),
      PromptConfig.summaryDefault(),
    ];

    // 创建默认LLM配置
    final defaultModels = [
      LLMConfig.openAIDefault(),
    ];

    // 创建默认同步配置
    final defaultSync = [
      SyncConfig.defaultConfig(),
    ];

    return AppConfig(
      diaryMode: DiaryMode.qa,
      theme: ThemeModeType.light,
      model: defaultModels,
      prompt: defaultPrompts,
      sync: defaultSync,
      qaQuestions: const [],
    );
  }

  factory AppConfig.fromMap(Map map) => AppConfig(
        diaryMode: diaryModeFromString(map['diary_mode'] ?? 'qa'),
        model: (map['model'] as List? ?? []).map((e) => LLMConfig.fromMap(e)).toList(),
        prompt: (map['prompt'] as List? ?? []).map((e) => PromptConfig.fromMap(e)).toList(),
        theme: themeModeTypeFromString(map['theme'] ?? 'light'),
        sync: (map['sync'] as List? ?? []).map((e) => SyncConfig.fromMap(e)).toList(),
        qaQuestions: (map['qa_questions'] as List? ?? []).map((e) => e.toString()).toList(),
      );
  Map<String, dynamic> toMap() => {
        'diary_mode': diaryModeToString(diaryMode),
        'model': model.map((e) => e.toMap()).toList(),
        'prompt': prompt.map((e) => e.toMap()).toList(),
        'theme': themeModeTypeToString(theme),
        'sync': sync.map((e) => e.toMap()).toList(),
        'qa_questions': qaQuestions,
      };
}
