import '../model/enums.dart';
import '../model/prompt_config.dart';
import '../model/prompt_constants.dart';
import 'config_service.dart';
import 'dart:convert';
import 'dart:io';
import '../util/storage_service.dart';
import '../util/prompt_util.dart';

class PromptConfigService {
  static Future<void> init() async {
    // 加载配置
    await AppConfigService.load();

    // 确保默认提示词存在
    await _ensureDefaultPrompts();

    // 确保每种类型的提示词都有一个激活项
    await _ensureActivePrompts();
  }

  /// 确保默认提示词存在
  static Future<void> _ensureDefaultPrompts() async {
    final config = await AppConfigService.load();

    bool needsSave = false;

    // 检查是否有聊天类型的提示词
    final chatPrompts = config.prompt.where((p) => p.type == PromptCategory.chat).toList();
    if (chatPrompts.isEmpty) {
      print('[PromptConfigService] 没有找到聊天类型的提示词，创建默认提示词');
      config.prompt.add(PromptConfig.chatDefault());
      needsSave = true;
    }

    // 检查是否有总结类型的提示词
    final summaryPrompts = config.prompt.where((p) => p.type == PromptCategory.summary).toList();
    if (summaryPrompts.isEmpty) {
      print('[PromptConfigService] 没有找到总结类型的提示词，创建默认提示词');
      config.prompt.add(PromptConfig.summaryDefault());
      needsSave = true;
    }

    if (needsSave) {
      await AppConfigService.save();
      print('[PromptConfigService] 已保存默认提示词到配置文件');
    }
  }

  // 新增: 持久化 Prompt 配置到 lumma_config.json，并格式化保存
  static Future<void> save() async {
    final config = await AppConfigService.load();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(config.toMap());
    final filePath = await StorageService.getAppConfigFilePath();
    final file = File(filePath);
    await file.writeAsString(jsonStr);
  }

  /// 确保每种类型的提示词都有一个激活项
  static Future<void> _ensureActivePrompts() async {
    for (final category in PromptCategory.values) {
      final prompts = await listPrompts(category: category);
      if (prompts.isNotEmpty) {
        // 检查是否有激活的提示词
        final activeContent = await getActivePromptContent(category);
        if (activeContent == null || activeContent.isEmpty) {
          // 如果没有激活的提示词，将第一个设为激活
          final firstPrompt = prompts.first;
          print('[PromptConfigService] 类型 $category 没有激活的提示词，将 ${firstPrompt.name} 设为激活');
          await setActivePrompt(category, firstPrompt.name);
        }
      }
    }
  }

  /// 创建缺少的系统提示词
  static Future<int> createMissingSystemPrompts() async {
    final config = await AppConfigService.load();
    final systemPrompts = PromptConstants.getAllSystemPrompts();

    int createdCount = 0;

    for (final systemPromptData in systemPrompts) {
      final name = systemPromptData['name'] as String;
      final type = promptCategoryFromString(systemPromptData['type'] as String);
      final content = systemPromptData['content'] as String;
      final isSystem = systemPromptData['isSystem'] as bool;

      // 检查是否已经存在
      final exists = config.prompt.any((p) => p.name == name && p.type == type);

      if (!exists) {
        print('[PromptConfigService] 创建缺少的系统提示词: $name');
        final newPrompt = PromptConfig(
          name: name,
          type: type,
          content: content,
          isSystem: isSystem,
          active: false, // 默认不激活，让用户手动激活
        );

        config.prompt.add(newPrompt);
        createdCount++;
      }
    }

    if (createdCount > 0) {
      await AppConfigService.save();
      print('[PromptConfigService] 成功创建了 $createdCount 个系统提示词');
    }

    return createdCount;
  }
}
