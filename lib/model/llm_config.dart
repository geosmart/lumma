import 'timestamped.dart';

class LLMConfig extends Timestamped {
  String provider;
  String baseUrl;
  String apiKey;
  String model;
  bool active;

  LLMConfig({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.active = false,
    DateTime? created,
    DateTime? updated,
  }) : super(created: created, updated: updated);

  /// 创建默认的LLM配置（OpenAI）
  factory LLMConfig.openAIDefault() => LLMConfig(
        provider: 'openrouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: 'sk-or-v1-83ccf61c5dba0cd6aca513a898f35ee0a18603157cb1400de28d1697c8b7e',
        model: 'deepseek/deepseek-chat-v3-0324:free',
        active: true,
      );


  factory LLMConfig.fromMap(Map map) => LLMConfig(
        provider: map['provider'] ?? '',
        baseUrl: map['baseUrl'] ?? '',
        apiKey: map['apiKey'] ?? '',
        model: map['model'] ?? '',
        active: map['active'] ?? false,
        created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
        updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'provider': provider,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        'active': active,
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };
}
