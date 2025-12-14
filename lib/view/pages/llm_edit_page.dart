import 'package:flutter/material.dart';
import 'package:lumma/model/llm_config.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';

class LLMEditPage extends StatefulWidget {
  final LLMConfig? config;
  final bool readOnly;

  const LLMEditPage({super.key, this.config, this.readOnly = false});

  @override
  State<LLMEditPage> createState() => _LLMEditPageState();
}

class _LLMEditPageState extends State<LLMEditPage> {
  late TextEditingController _providerCtrl;
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;
  bool _isDefault = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _providerCtrl = TextEditingController(text: config?.provider ?? '');
    _baseUrlCtrl = TextEditingController(text: config?.baseUrl ?? '');
    _apiKeyCtrl = TextEditingController(text: config?.apiKey ?? '');
    _modelCtrl = TextEditingController(text: config?.model ?? '');
    _isDefault = config?.provider == 'default';
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final newConfig = LLMConfig(
      provider: _providerCtrl.text,
      baseUrl: _baseUrlCtrl.text,
      apiKey: _apiKeyCtrl.text,
      model: _modelCtrl.text,
      active: widget.config?.active ?? false,
      isSystem: widget.config?.isSystem ?? false, // 保留系统级标识
      created: widget.config?.created,
      updated: DateTime.now(),
    );
    Navigator.of(context).pop(newConfig);
  }

  void _resetConfig() async {
    final config = widget.config;
    if (config == null || !config.isSystem) return;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Localizations.localeOf(context).languageCode == 'zh' ? '确认重置' : 'Confirm Reset'),
        content: Text(
          Localizations.localeOf(context).languageCode == 'zh'
              ? '确定要重置此模型配置到默认内容吗？'
              : 'Are you sure you want to reset this model configuration to default content?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Localizations.localeOf(context).languageCode == 'zh' ? '取消' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Localizations.localeOf(context).languageCode == 'zh' ? '重置' : 'Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 根据provider类型获取对应的默认配置
      LLMConfig? defaultConfig;
      if (config.provider == 'openrouter') {
        defaultConfig = LLMConfig.openRouterDefault();
      } else if (config.provider == 'deepseek') {
        defaultConfig = LLMConfig.deepSeekDefault();
      }

      if (defaultConfig != null) {
        // 重置为默认值
        setState(() {
          _providerCtrl.text = defaultConfig!.provider;
          _baseUrlCtrl.text = defaultConfig.baseUrl;
          _apiKeyCtrl.text = defaultConfig.apiKey;
          _modelCtrl.text = defaultConfig.model;
        });

        // 显示重置成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'zh'
                    ? '模型配置已重置到默认内容'
                    : 'Model configuration has been reset to default content',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('[LLMEditPage] 重置模型配置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '重置模型配置失败: $e'
                  : 'Failed to reset model configuration: $e',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.readOnly || _isDefault;
    final isSystemConfig = widget.config?.isSystem ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.config == null
              ? AppLocalizations.of(context)!.llmEditAddTitle
              : widget.readOnly
              ? (Localizations.localeOf(context).languageCode == 'zh' ? '查看模型配置' : 'View Model Configuration')
              : AppLocalizations.of(context)!.llmEditEditTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _providerCtrl,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.llmEditProvider),
                      readOnly: isReadOnly || isSystemConfig, // 系统级配置不允许修改provider
                    ),
                    TextField(
                      controller: _baseUrlCtrl,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.llmEditBaseUrl),
                      readOnly: isReadOnly,
                    ),
                    TextField(
                      controller: _apiKeyCtrl,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.llmEditApiKey,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureApiKey = !_obscureApiKey;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureApiKey,
                      readOnly: isReadOnly,
                    ),
                    TextField(
                      controller: _modelCtrl,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.llmEditModel),
                      readOnly: isReadOnly || isSystemConfig, // 系统级配置不允许修改model
                    ),
                  ],
                ),
              ),
            ),
            // 对于系统级配置，显示重置按钮
            if (isSystemConfig && !widget.readOnly) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton.icon(
                  onPressed: _resetConfig,
                  icon: const Icon(Icons.smart_toy), // 使用AI机器人图标
                  label: Text(Localizations.localeOf(context).languageCode == 'zh' ? '重置到默认' : 'Reset to Default'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: isReadOnly ? null : _saveConfig,
                icon: const Icon(Icons.psychology), // 使用AI大脑图标
                label: Text(AppLocalizations.of(context)!.llmEditSave),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
