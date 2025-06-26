import 'dart:convert';

class ModelConfig {
  String provider;
  String baseUrl;
  String apiKey;
  String model;
  bool isActive;

  ModelConfig({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.isActive = false,
  });

  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
        provider: json['provider'],
        baseUrl: json['baseUrl'],
        apiKey: json['apiKey'],
        model: json['model'],
        isActive: json['isActive'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'baseUrl': baseUrl,
        'apiKey': apiKey,
        'model': model,
        'isActive': isActive,
      };

  static List<ModelConfig> listFromJson(String source) {
    final List<dynamic> data = json.decode(source);
    return data.map((e) => ModelConfig.fromJson(e)).toList();
  }

  static String listToJson(List<ModelConfig> configs) {
    return json.encode(configs.map((e) => e.toJson()).toList());
  }
}
