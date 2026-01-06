import 'package:flutter/material.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/config/settings_ui_config.dart';
import 'package:lumma/service/config_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class McpConfigPage extends StatefulWidget {
  const McpConfigPage({super.key});

  @override
  State<McpConfigPage> createState() => _McpConfigPageState();
}

class _McpConfigPageState extends State<McpConfigPage> {
  String? _mcpUrl;
  String? _mcpApiKey;
  bool _isLoading = true;
  bool _obscureMcpUrl = true;
  bool _obscureMcpApiKey = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadMcpConfig();
  }

  Future<void> _loadMcpConfig() async {
    setState(() {
      _isLoading = true;
    });
    final appConfig = await AppConfigService.load();
    setState(() {
      _mcpUrl = appConfig.sync.mcpUrl;
      _mcpApiKey = appConfig.sync.mcpApiKey;
      _isLoading = false;
    });
  }

  Future<void> _saveMcpConfig() async {
    await AppConfigService.update((config) {
      config.sync.mcpUrl = _mcpUrl ?? '';
      config.sync.mcpApiKey = _mcpApiKey ?? '';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.mcpConfigSaved)),
      );
    }
  }

  Future<void> _testMcpConnection() async {
    final url = _mcpUrl?.trim() ?? '';
    final apiKey = _mcpApiKey?.trim() ?? '';

    if (url.isEmpty || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseCompleteMcpConfig)),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      // 发送测试请求到 MCP 服务器
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ping',
          'id': 1,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mcpConnectionSuccess)),
          );
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mcpAuthenticationFailed)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mcpConnectionFailed(response.statusCode))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mcpConnectionError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.backgroundGradient,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 页面标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                Icon(Icons.cloud_queue, color: context.primaryTextColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.mcpConfig,
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // MCP 配置卡片
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.settings_ethernet, color: context.primaryTextColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.mcpServerConfig,
                      style: TextStyle(
                        fontSize: SettingsUiConfig.titleFontSize,
                        fontWeight: SettingsUiConfig.titleFontWeight,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // MCP URL 输入
                TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.mcpUrl,
                    hintText: AppLocalizations.of(context)!.mcpUrlPlaceholder,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureMcpUrl ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureMcpUrl = !_obscureMcpUrl;
                        });
                      },
                    ),
                  ),
                  controller: TextEditingController(text: _mcpUrl ?? '')
                    ..selection = TextSelection.collapsed(offset: (_mcpUrl ?? '').length),
                  onChanged: (v) => _mcpUrl = v,
                  obscureText: _obscureMcpUrl,
                  maxLines: 1,
                ),
                const SizedBox(height: 12),

                // API Key 输入
                TextField(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.mcpApiKey,
                    hintText: AppLocalizations.of(context)!.mcpApiKeyPlaceholder,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureMcpApiKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureMcpApiKey = !_obscureMcpApiKey;
                        });
                      },
                    ),
                  ),
                  controller: TextEditingController(text: _mcpApiKey ?? '')
                    ..selection = TextSelection.collapsed(offset: (_mcpApiKey ?? '').length),
                  onChanged: (v) => _mcpApiKey = v,
                  obscureText: _obscureMcpApiKey,
                  maxLines: 1,
                ),
                const SizedBox(height: 16),

                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveMcpConfig,
                      icon: const Icon(Icons.save),
                      label: Text(AppLocalizations.of(context)!.saveConfig),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isTesting ? null : _testMcpConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_done),
                      label: Text(AppLocalizations.of(context)!.testConnection),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 说明信息卡片
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: context.primaryTextColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.mcpConfigInfo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.mcpConfigDescription,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.secondaryTextColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
