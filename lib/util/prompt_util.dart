import '../model/enums.dart';
import '../model/prompt_config.dart';
import '../config/config_service.dart';

/// 获取指定类型的激活prompt内容
Future<String?> getActivePromptContent(PromptCategory category) async {
  final config = await AppConfigService.load();
  final prompt = config.prompt.firstWhere(
    (p) => p.type == category && p.active,
    orElse: () => config.prompt.firstWhere(
      (p) => p.type == category,
      orElse: () => PromptConfig.qaDefault(),
    ),
  );
  return prompt.content;
}

/// 获取指定类型的激活prompt名称
Future<String?> getActivePromptName(PromptCategory category) async {
  final config = await AppConfigService.load();
  final prompt = config.prompt.firstWhere(
    (p) => p.type == category && p.active,
    orElse: () => config.prompt.firstWhere(
      (p) => p.type == category,
      orElse: () => PromptConfig.qaDefault(),
    ),
  );
  return prompt.name;
}

/// 设置指定类型的激活prompt（只允许一个active）
Future<void> setActivePrompt(PromptCategory category, String name) async {
  await AppConfigService.update((config) {
    for (final p in config.prompt) {
      if (p.type == category) {
        p.active = (p.name == name);
      }
    }
  });
}

/// 新增或编辑prompt
Future<void> savePrompt(PromptConfig prompt, {String? oldName}) async {
  await AppConfigService.update((config) {
    if (oldName != null) {
      config.prompt.removeWhere((p) => p.name == oldName && p.type == prompt.type);
    } else {
      config.prompt.removeWhere((p) => p.name == prompt.name && p.type == prompt.type);
    }
    config.prompt.add(prompt);
  });
}

/// 删除prompt
Future<void> deletePrompt(PromptCategory category, String name) async {
  await AppConfigService.update((config) {
    config.prompt.removeWhere((p) => p.type == category && p.name == name);
  });
}

/// 获取所有prompt（可选按类型过滤）
Future<List<PromptConfig>> listPrompts({PromptCategory? category}) async {
  final config = await AppConfigService.load();
  if (category == null) return config.prompt;
  return config.prompt.where((p) => p.type == category).toList();
}
