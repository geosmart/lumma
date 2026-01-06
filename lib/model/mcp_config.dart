class McpConfig {
  bool enabled;
  String url;
  String token;
  String? entityId;

  McpConfig({
    this.enabled = false,
    this.url = '',
    this.token = '',
    this.entityId,
  });

  factory McpConfig.defaultConfig() {
    return McpConfig(
      enabled: false,
      url: 'https://mcp-web-url/mcp/v1/message',
      token: '',
      entityId: '',
    );
  }

  factory McpConfig.fromMap(Map map) => McpConfig(
    enabled: map['enabled'] ?? false,
    url: map['url'] ?? 'https://mcp-web-url/mcp/v1/message',
    token: map['token'] ?? '',
    entityId: map['entity_id'],
  );

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'url': url,
    'token': token,
    'entity_id': entityId,
  };

  bool get isConfigured => enabled && url.isNotEmpty && token.isNotEmpty && (entityId?.isNotEmpty ?? false);
}
