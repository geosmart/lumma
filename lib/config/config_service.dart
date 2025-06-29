import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../model/app_config.dart';
import 'theme_service.dart';
import 'llm_config_service.dart';
import 'prompt_config_service.dart';
import '../diary/qa_questions_service.dart';
import 'diary_mode_config_service.dart';

class AppConfigService {
  static AppConfig? _cache;
  static const String configFileName = 'lumma_config.json';

  static Future<File> _getConfigFile() async {
    final dir = await getApplicationDocumentsDirectory();
    var confPath='${dir.path}$configFileName';
    // 返回配置文件路径
    print('[AppConfigService] 配置文件路径: $confPath');
    return File(confPath);
  }

  static Future<AppConfig> load() async {
    try {
      if (_cache != null) return _cache!;
      final file = await _getConfigFile();
      if (!await file.exists()) {
        _cache = AppConfig.defaultConfig();
        return _cache!;
      }
      final content = await file.readAsString();
      final map = content.isNotEmpty ? jsonDecode(content) : {};
      _cache = AppConfig.fromMap(map);
      return _cache!;
    } catch (e, stack) {
      // 日志输出异常，返回默认配置
      print('[AppConfigService] 加载配置异常: $e\n$stack');
      _cache = AppConfig.defaultConfig();
      return _cache!;
    }
  }

  static Future<void> save() async {
    try {
      print('[AppConfigService] save() called');
      if (_cache != null) {
        final file = await _getConfigFile();
        await file.writeAsString(jsonEncode(_cache!.toMap()));
        print('[AppConfigService] 保存配置: ${jsonEncode(_cache!.toMap())}');
      }
    } catch (e, stack) {
      print('[AppConfigService] 保存配置异常: $e\n$stack');
      rethrow;
    }
  }

  static Future<void> update(void Function(AppConfig) updater) async {
    try {
      final config = await load();
      updater(config);
      await save();
    } catch (e, stack) {
      print('[AppConfigService] 更新配置异常: $e\n$stack');
      rethrow;
    }
  }

  static Future<void> clearCache() async {
    _cache = null;
  }

  static Future<void> init() async {
    // 主入口，初始化所有配置
    await LlmConfigService.init();
    await PromptConfigService.init();
    await QaQuestionsService.init();
    await ThemeService.instance.init();
    await DiaryModeConfigService.init();
    // 可扩展：如有其它配置类，继续调用其 init
    // 例如：await SyncConfigService.init?.call();
  }
}
