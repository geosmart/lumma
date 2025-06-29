import '../model/prompt_config.dart';
import '../model/enums.dart';
import 'config_service.dart';
import 'prompt_service.dart';

class PromptConfigService {
  static Future<void> init() async {
    // 加载配置
    await AppConfigService.load();

    // 检查磁盘上是否有提示词文件
    final promptFiles = await PromptService.listPrompts();

    // 如果磁盘上没有提示词文件，初始化默认提示词
    if (promptFiles.isEmpty) {
      print('[PromptConfigService] 磁盘中没有提示词文件，初始化默认Prompt配置');

      // 使用模型内置的默认值
      final promptQa = PromptConfig.qaDefault();
      final promptSummary = PromptConfig.summaryDefault();

      // 获取文件名
      final qaFileName = PromptConfig.getDefaultFileName(PromptCategory.qa);
      final summaryFileName = PromptConfig.getDefaultFileName(PromptCategory.summary);

      // 保存到 AppConfig
      await AppConfigService.update((c) => c.prompt = [promptQa, promptSummary]);

      // 将默认提示词保存为文件
      await PromptService.savePrompt(
        fileName: qaFileName,
        content: promptQa.content,
        type: promptQa.type,
      );

      await PromptService.savePrompt(
        fileName: summaryFileName,
        content: promptSummary.content,
        type: promptSummary.type,
      );

      // 设置默认提示词为激活状态
      await PromptService.setActivePrompt(PromptCategory.qa, qaFileName);

      print('[PromptConfigService] 成功初始化默认提示词并保存为文件');
    } else {
      print('[PromptConfigService] 磁盘上已有提示词文件，无需初始化默认提示词');

      // 确保每种类型有一个激活的提示词
      await _ensureActivePrompts();
    }
  }

  // 新增: 持久化 Prompt 配置到 lumma_config.json
  static Future<void> save() async {
    // 假设 prompt 配置已在 AppConfig 中，直接调用 AppConfigService.save()
    await AppConfigService.save();
  }

  /// 确保每种类型的提示词都有一个激活项
  static Future<void> _ensureActivePrompts() async {
    for (final category in PromptService.promptCategories) {
      final files = await PromptService.listPrompts(category: category);
      if (files.isNotEmpty) {
        // 检查是否有激活的提示词
        final activeFile = await PromptService.getActivePromptFile(category);
        if (activeFile == null) {
          // 如果没有激活的提示词，将第一个设为激活
          final firstFile = files.first;
          final fileName = firstFile.path.split('/').last;
          print('[PromptConfigService] 类型 $category 没有激活的提示词，将 $fileName 设为激活');
          await PromptService.setActivePrompt(category, fileName);
        }
      }
    }
  }
}
