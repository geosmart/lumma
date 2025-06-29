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
