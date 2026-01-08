class McpConfig {
  bool enabled;
  String url;
  String token;
  String? entityName;

  McpConfig({
    this.enabled = false,
    this.url = '',
    this.token = '',
    this.entityName,
  });

  factory McpConfig.defaultConfig() {
    return McpConfig(
      enabled: false,
      url: 'https://mcp-web-url/mcp/v1/message',
      token: '',
      entityName: '',
    );
  }

  factory McpConfig.fromMap(Map map) => McpConfig(
    enabled: map['enabled'] ?? false,
    url: map['url'] ?? 'https://mcp-web-url/mcp/v1/message',
    token: map['token'] ?? '',
    entityName: map['entityName'],
  );

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'url': url,
    'token': token,
    'entityName': entityName,
  };

  bool get isConfigured => enabled && url.isNotEmpty && token.isNotEmpty && (entityName?.isNotEmpty ?? false);
}
