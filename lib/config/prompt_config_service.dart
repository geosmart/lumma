import '../model/enums.dart';
import 'config_service.dart';
import 'dart:convert';
import 'dart:io';
import '../util/storage_service.dart';
import '../util/prompt_util.dart';

class PromptConfigService {
  static Future<void> init() async {
    // 加载配置
    await AppConfigService.load();
    // 只需保证AppConfig中的prompt有内容，无需再操作md文件
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
}
