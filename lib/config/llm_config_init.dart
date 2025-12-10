import 'dart:io';
import 'package:flutter/foundation.dart';
import '../model/llm_config.dart';
import 'package:lumma/service/config_service.dart';
import '../model/prompt_config.dart';
import 'prompt_constants.dart';
import '../model/enums.dart';

/// 初始化 LLM 和 Prompt 配置，如果没有则从 .env 读取并写入
Future<void> ensureConfig() async {
  final config = await AppConfigService.load();
  final env = await _readEnv();
  bool updated = false;

  // LLM 初始化
  if (config.model.isEmpty) {
    final llm = LLMConfig(
      provider: env['MODEL_PROVIDER'] ?? '',
      baseUrl: env['MODEL_BASE_URL'] ?? '',
      apiKey: env['MODEL_API_KEY'] ?? '',
      model: env['MODEL_NAME'] ?? '',
      active: true,
    );
    config.model = [llm];
    updated = true;
    debugPrint('[ensureLlmAndPromptConfigFromEnv] 已根据 .env 初始化 LLM 配置');
  }

  // 系统提示词初始化（不可删除）
  final existingPromptNames = config.prompt.map((p) => p.name).toSet();
  final missingPrompts = PromptConstants.getSystemChatPrompts()
      .where((e) => !existingPromptNames.contains(e['name']!))
      .toList();
  if (missingPrompts.isNotEmpty) {
    config.prompt.addAll(
      missingPrompts.map(
        (e) => PromptConfig(
          name: e['name']!,
          type: PromptCategory.chat,
          active: false,
          content: e['content']!,
          isSystem: true, // 系统级提示词
        ),
      ),
    );
    updated = true;
    debugPrint('[ensureLlmAndPromptConfigFromEnv] 已补全缺失的系统提示词');
  }

  if (updated) {
    await AppConfigService.update((c) {
      c.model = config.model;
      c.prompt = config.prompt;
    });
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
