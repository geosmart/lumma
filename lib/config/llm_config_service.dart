import '../model/llm_config.dart';
import 'config_service.dart';
import 'dart:io';

class LlmConfigService {
  static Future<void> init() async {
    final config = await AppConfigService.load();
    if (config.model.isEmpty) {
      final env = await _readEnv();
      final llm = LLMConfig(
        provider: env['MODEL_PROVIDER'] ?? '',
        baseUrl: env['MODEL_BASE_URL'] ?? '',
        apiKey: env['MODEL_API_KEY'] ?? '',
        model: env['MODEL_NAME'] ?? '',
        active: true,
      );
      await AppConfigService.update((c) => c.model = [llm]);
    }
  }

  // 新增: 持久化模型配置到 lumma_config.json
  static Future<void> save() async {
    // 假设模型配置已在 AppConfig 中，直接调用 AppConfigService.save()
    await AppConfigService.save();
  }

  /// 创建缺少的系统LLM配置
  static Future<int> createMissingSystemConfigs() async {
    final config = await AppConfigService.load();
    final systemConfigs = LLMConfig.getAllSystemConfigs();

    int createdCount = 0;

    for (final systemConfig in systemConfigs) {
      // 检查是否已经存在相同的系统配置
      final exists = config.model.any((llm) =>
          llm.provider == systemConfig.provider &&
          llm.baseUrl == systemConfig.baseUrl &&
          llm.model == systemConfig.model &&
          llm.isSystem == true);

      if (!exists) {
        print('[LlmConfigService] 创建缺少的系统LLM配置: ${systemConfig.provider} - ${systemConfig.model}');
        config.model.add(systemConfig);
        createdCount++;
      }
    }

    if (createdCount > 0) {
      await AppConfigService.save();
      print('[LlmConfigService] 成功创建了 $createdCount 个系统LLM配置');
    }

    return createdCount;
  }
}

Future<Map<String, String>> _readEnv() async {
  final file = File('.env');
  if (!await file.exists()) return {};
  final lines = await file.readAsLines();
  final map = <String, String>{};
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx > 0) {
      final key = trimmed.substring(0, idx).trim();
      final value = trimmed.substring(idx + 1).trim();
      map[key] = value;
    }
  }
  return map;
}
