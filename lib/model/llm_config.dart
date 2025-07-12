import 'timestamped.dart';

class LLMConfig extends Timestamped {
  String provider;
  String baseUrl;
  String apiKey;
  String model;
  bool active;
  bool isSystem; // 新增：是否为系统级LLM配置

  LLMConfig({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.active = false,
    this.isSystem = false, // 默认不是系统级
    super.created,
    super.updated,
  });

  factory LLMConfig.openRouterDefault() => LLMConfig(
        provider: 'openrouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: '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',
        model: 'deepseek/deepseek-chat-v3-0324:free',
        active: true,
        isSystem: true, // 标记为系统级配置
      );

  /// 创建默认的LLM配置（OpenAI）
  factory LLMConfig.deepSeekDefault() => LLMConfig(
        provider: 'deepseek',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: 'sk-xxx',
        model: 'deepseek-chat',
        active: false,
        isSystem: true, // 标记为系统级配置
      );

  /// 获取所有应该存在的系统LLM配置
  static List<LLMConfig> getAllSystemConfigs() {
    return [
      LLMConfig.openRouterDefault(),
      LLMConfig.deepSeekDefault(),
    ];
  }

  factory LLMConfig.fromMap(Map map) => LLMConfig(
        provider: map['provider'] ?? '',
        baseUrl: map['baseUrl'] ?? '',
        apiKey: map['apiKey'] ?? '',
        model: map['model'] ?? '',
        active: map['active'] ?? false,
        isSystem: map['isSystem'] == true, // 更安全的处理，默认为false
        created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
        updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'provider': provider,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        'active': active,
        'isSystem': isSystem, // 新增字段
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };
}
