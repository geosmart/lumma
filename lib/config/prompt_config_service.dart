import '../model/enums.dart';
import '../model/prompt_config.dart';
import '../model/prompt_constants.dart';
import 'config_service.dart';
import 'language_service.dart';
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

  /// 复制提示词（创建一个可编辑的副本）
  static Future<PromptConfig> copyPrompt(PromptConfig originalPrompt) async {
    // 生成新的名称（添加"副本"后缀）
    String newName = originalPrompt.name;
    if (newName.endsWith('.md')) {
      newName = newName.substring(0, newName.length - 3);
    }

    // 检查是否已经有副本，如果有则添加数字后缀
    final config = await AppConfigService.load();
    final existingPrompts = config.prompt.where((p) => p.type == originalPrompt.type).toList();

    // 根据语言设置生成副本名称
    final languageService = LanguageService.instance;
    final isZh = languageService.currentLocale.languageCode == 'zh';
    final copyText = isZh ? '副本' : 'Copy';

    String baseName = '$newName $copyText';
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
    config.prompt.add(newPrompt);
    await AppConfigService.save();

    return newPrompt;
  }

  /// 重置提示词到默认内容
  static Future<void> resetPrompt(PromptConfig prompt) async {
    final config = await AppConfigService.load();

    // 找到对应的提示词
    final index = config.prompt.indexWhere(
      (p) => p.name == prompt.name && p.type == prompt.type
    );

    if (index == -1) {
      throw Exception('Prompt not found');
    }

    // 获取默认内容
    String defaultContent;
    switch (prompt.type) {
      case PromptCategory.chat:
        defaultContent = PromptConstants.getDefaultChatPrompt();
        break;
      case PromptCategory.summary:
        defaultContent = PromptConstants.getDefaultSummaryPrompt();
        break;
    }

    // 更新提示词内容
    config.prompt[index] = PromptConfig(
      name: prompt.name,
      type: prompt.type,
      content: defaultContent,
      isSystem: prompt.isSystem,
      active: prompt.active,
      created: prompt.created,
      updated: DateTime.now(),
    );

    await AppConfigService.save();
    print('[PromptConfigService] 已重置提示词: ${prompt.name}');
  }
}
