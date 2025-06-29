import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'model_config.dart';

class ConfigService {
  static const String _fileName = 'model_configs.json';

  static Future<List<ModelConfig>> loadModelConfigs() async {
    final file = await _projectModelConfigFile;
    if (!await file.exists()) {
      return [];
    }
    final content = await file.readAsString();
    if (content.isEmpty) return [];
    return ModelConfig.listFromJson(content);
  }

  static Future<ModelConfig> loadActiveModelConfig() async {
    final configs = await loadModelConfigs();
    if (configs.isEmpty) {
      throw Exception('No model configurations found.');
    }
    return configs.firstWhere((c) => c.active, orElse: () => configs.first);
  }

  static Future<void> saveModelConfigs(List<ModelConfig> configs, {BuildContext? context}) async {
    try {
      final file = context == null
          ? await _projectModelConfigFile
          : await getProjectModelConfigFileWithContext(context);
      await file.writeAsString(ModelConfig.listToJson(configs));
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存模型配置失败: \n${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  static Future<void> ensureDefaultConfig({BuildContext? context}) async {
    final configs = await loadModelConfigs();
    if (configs.isEmpty) {
      ModelConfig defaultConfig = ModelConfig(
        provider: dotenv.env['MODEL_PROVIDER'] ?? 'openrouter',
        baseUrl: dotenv.env['MODEL_BASE_URL'] ?? 'https://openrouter.ai/api/v1',
        apiKey: dotenv.env['MODEL_API_KEY'] ?? '替换为你的apikey',
        model: dotenv.env['MODEL_NAME'] ?? 'deepseek/deepseek-chat-v3-0324:free',
        active: true,
      );
      final dir = await getProjectConfigDir(context: context);
      final file = File(p.join(dir, 'model_default.json'));
      await file.writeAsString(jsonEncode(defaultConfig.toJson()));
      await saveModelConfigs([defaultConfig], context: context);
    }
  }

  // diary_configs.json 相关
  static const String _diaryConfigFileName = 'diary_configs.json';
  static Future<File> get _projectDiaryConfigFile async {
    final dir = await getProjectConfigDir();
    return File(p.join(dir, _diaryConfigFileName));
  }

  static Future<Map<String, dynamic>> loadDiaryConfigs() async {
    final file = await _projectDiaryConfigFile;
    if (!await file.exists()) {
      return {};
    }
    final content = await file.readAsString();
    if (content.isEmpty) return {};
    return jsonDecode(content);
  }

  static Future<void> saveDiaryConfigs(Map<String, dynamic> config) async {
    final file = await _projectDiaryConfigFile;
    await file.writeAsString(jsonEncode(config));
  }

  static Future<void> ensureDefaultDiaryConfigs() async {
    final config = await loadDiaryConfigs();
    if (config.isEmpty) {
      final defaultConfig = {'mode': 0};
      await saveDiaryConfigs(defaultConfig);
    }
  }

  // qa_questions.json 相关
  static const String _qaConfigFileName = 'qa_questions.json';
  static Future<File> get _projectQaConfigFile async {
    final dir = await getProjectConfigDir();
    return File(p.join(dir, _qaConfigFileName));
  }

  static Future<List<String>> loadQaQuestions() async {
    final file = await _projectQaConfigFile;
    if (!await file.exists()) {
      await ensureDefaultQaQuestions();
      // after ensuring default, load again
      final defaultFile = await _projectQaConfigFile;
      final content = await defaultFile.readAsString();
      final questions = jsonDecode(content) as List<dynamic>;
      return questions.cast<String>();
    }
    final content = await file.readAsString();
    if (content.isEmpty) {
      await ensureDefaultQaQuestions();
      final defaultFile = await _projectQaConfigFile;
      final newContent = await defaultFile.readAsString();
      final questions = jsonDecode(newContent) as List<dynamic>;
      return questions.cast<String>();
    }
    final questions = jsonDecode(content) as List<dynamic>;
    return questions.cast<String>();
  }

  static Future<void> saveQaQuestions(List<String> questions) async {
    final file = await _projectQaConfigFile;
    await file.writeAsString(jsonEncode(questions));
  }

  static Future<void> ensureDefaultQaQuestions() async {
    final file = await _projectQaConfigFile;
    if (!await file.exists()) {
      final List<String> defaultQuestions = [
        '今天哪些细节引起了你的注意？',
        '今天谁做了什么具体的事？',
        '今天你做成了什么事？',
        '什么时候你感到开心、轻松或觉得有趣？',
        '今天你收到了哪些支持或善意？',
        '今天你遇到了哪些外部挑战？',
        '你在什么时候感受到不适的情绪？',
        '你的身体有没有发出一些信号？',
        '我今天又出现了什么反应模式？',
        '针对今日问题制定明日可行的小步优化？',
      ];
      await saveQaQuestions(defaultQuestions);
    }
  }

  // 统一获取应用私有目录下 config 目录
  static Future<String> getProjectConfigDir({BuildContext? context}) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final configDir = Directory(p.join(appDocDir.path, 'config'));
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return configDir.path;
  }

  static Future<File> get _projectModelConfigFile async {
    final dir = await getProjectConfigDir();
    return File(p.join(dir, _fileName));
  }

  // 支持 context 的配置文件获取（用于弹窗提示）
  static Future<File> getProjectModelConfigFileWithContext(BuildContext context) async {
    final dir = await getProjectConfigDir(context: context);
    return File(p.join(dir, _fileName));
  }
}
