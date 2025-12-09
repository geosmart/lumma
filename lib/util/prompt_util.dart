import 'package:lumma/model/enums.dart';
import 'package:lumma/model/prompt_config.dart';
import 'package:lumma/service/config_service.dart';

/// 获取指定类型的激活prompt内容
Future<String?> getActivePromptContent(PromptCategory category) async {
  final config = await AppConfigService.load();
  final prompt = config.prompt.firstWhere(
    (p) => p.type == category && p.active,
    orElse: () => config.prompt.firstWhere((p) => p.type == category, orElse: () => PromptConfig.chatDefault()),
  );
  return prompt.content;
}

/// 获取指定类型的激活prompt名称
Future<String?> getActivePromptName(PromptCategory category) async {
  final config = await AppConfigService.load();
  final prompt = config.prompt.firstWhere(
    (p) => p.type == category && p.active,
    orElse: () => PromptConfig.chatDefault()..active = false,
  );
  return prompt.active ? prompt.name : null;
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

/// 禁用指定类型的激活prompt
Future<void> disableActivePrompt(PromptCategory category) async {
  await AppConfigService.update((config) {
    for (final p in config.prompt) {
      if (p.type == category) {
        p.active = false;
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

/// 复制prompt（创建一个可编辑的副本）
Future<PromptConfig> copyPrompt(PromptConfig originalPrompt) async {
  // 生成新的名称（添加"副本"后缀）
  String newName = originalPrompt.name;
  if (newName.endsWith('.md')) {
    newName = newName.substring(0, newName.length - 3);
  }

  // 检查是否已经有副本，如果有则添加数字后缀
  final config = await AppConfigService.load();
  final existingPrompts = config.prompt.where((p) => p.type == originalPrompt.type).toList();

  // 根据语言设置生成副本名称
  // 简单的语言检测，避免导入太多依赖
  String baseName = '$newName 副本'; // 默认中文，因为这是中文项目
  String finalName = baseName;
  int counter = 1;

  while (existingPrompts.any((p) => p.name == '$finalName.md')) {
    finalName = '$baseName $counter';
    counter++;
  }

  // 创建新的prompt配置
  final newPrompt = PromptConfig(
    name: '$finalName.md',
    type: originalPrompt.type,
    content: originalPrompt.content,
    isSystem: false, // 复制的提示词不是系统级的，可以编辑和删除
    active: false, // 默认不激活
  );

  // 保存新的prompt
  await savePrompt(newPrompt);

  return newPrompt;
}

/// 获取所有prompt（可选按类型过滤）
Future<List<PromptConfig>> listPrompts({PromptCategory? category}) async {
  final config = await AppConfigService.load();
  if (category == null) return config.prompt;
  return config.prompt.where((p) => p.type == category).toList();
}

/// 检查纠错功能是否启用
Future<bool> isCorrectionEnabled() async {
  final config = await AppConfigService.load();
  final correctionPrompts = config.prompt.where((p) => p.type == PromptCategory.correction && p.active).toList();
  return correctionPrompts.isNotEmpty;
}
