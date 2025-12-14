import 'package:flutter/material.dart';
import 'package:lumma/model/llm_config.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/config/settings_ui_config.dart';
import 'package:lumma/view/pages/llm_edit_page.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/service/ai_service.dart';

class LLMConfigPage extends StatefulWidget {
  const LLMConfigPage({super.key});

  @override
  State<LLMConfigPage> createState() => _LLMConfigPageState();
}

class _LLMConfigPageState extends State<LLMConfigPage> {
  List<LLMConfig> _configs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final appConfig = await AppConfigService.load();
    setState(() {
      _configs = List<LLMConfig>.from(appConfig.model);
      _loading = false;
    });
  }

  void _showEditDialog({LLMConfig? config, int? index, bool readOnly = false}) async {
    final result = await Navigator.of(context).push<LLMConfig>(
      MaterialPageRoute(
        builder: (context) => LLMEditPage(config: config, readOnly: readOnly),
      ),
    );

    if (result != null && !readOnly) {
      setState(() {
        if (index != null) {
          _configs[index] = result;
        } else {
          _configs.add(result);
        }
      });
      await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));
    }
  }

  void _deleteConfig(int index) async {
    // 系统级配置不可删除
    if (_configs[index].isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.localeOf(context).languageCode == 'zh'
                ? '系统配置不可删除'
                : 'System configuration cannot be deleted',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.llmDeleteConfirmTitle),
        content: Text(AppLocalizations.of(context)!.llmDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.llmCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.llmDelete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _configs.removeAt(index);
      await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));
      setState(() {});
    }
  }

  void _testConfig(int index) async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: context.cardBackgroundColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                Localizations.localeOf(context).languageCode == 'zh' ? '正在测试模型...' : 'Testing model...',
                style: TextStyle(color: context.primaryTextColor),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 构建测试消息
      final messages = [
        {
          'role': 'user',
          'content': Localizations.localeOf(context).languageCode == 'zh' ? '你是什么大模型？' : 'What AI model are you?',
        },
      ];

      // 临时切换到该配置进行测试
      final originalConfigs = List<LLMConfig>.from(_configs);
      for (var i = 0; i < _configs.length; i++) {
        _configs[i] = LLMConfig(
          provider: _configs[i].provider,
          baseUrl: _configs[i].baseUrl,
          apiKey: _configs[i].apiKey,
          model: _configs[i].model,
          active: i == index,
          isSystem: _configs[i].isSystem,
          created: _configs[i].created,
          updated: _configs[i].updated,
        );
      }
      await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));

      String response = '';
      int startTime = DateTime.now().millisecondsSinceEpoch;
      bool completed = false;

      await AiService.askStream(
        messages: messages,
        onDelta: (data) {
          response = data['content'] ?? '';
        },
        onDone: (data) {
          response = data['content'] ?? '';
          completed = true;
        },
        onError: (error) {
          response = 'Error: $error';
          completed = true;
        },
      );

      // 等待完成
      while (!completed) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      int endTime = DateTime.now().millisecondsSinceEpoch;
      int responseTime = endTime - startTime;

      // 恢复原始配置
      _configs = originalConfigs;
      await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));

      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      // 显示测试结果
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(Localizations.localeOf(context).languageCode == 'zh' ? '测试结果' : 'Test Result'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'zh'
                        ? '响应时间: ${responseTime}ms'
                        : 'Response time: ${responseTime}ms',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Localizations.localeOf(context).languageCode == 'zh' ? '模型回答:' : 'Model response:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(response),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(Localizations.localeOf(context).languageCode == 'zh' ? '关闭' : 'Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 关闭加载对话框
      if (mounted) Navigator.of(context).pop();

      // 显示错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Localizations.localeOf(context).languageCode == 'zh' ? '测试失败: $e' : 'Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _setActive(int index) async {
    for (var i = 0; i < _configs.length; i++) {
      _configs[i] = LLMConfig(
        provider: _configs[i].provider,
        baseUrl: _configs[i].baseUrl,
        apiKey: _configs[i].apiKey,
        model: _configs[i].model,
        active: i == index,
        isSystem: _configs[i].isSystem, // 保留系统级标识
        created: _configs[i].created,
        updated: DateTime.now(),
      );
    }
    await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));
    setState(() {});
  }

  void _resetConfig(int index) async {
    final config = _configs[index];
    if (!config.isSystem) return;

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
      // 获取默认系统配置
      final defaultConfig = LLMConfig.getAllSystemConfigs().firstWhere(
        (c) => c.provider == config.provider && c.baseUrl == config.baseUrl && c.model == config.model,
        orElse: () => config,
      );

      // 重置配置，保留原有的激活状态和时间戳
      _configs[index] = LLMConfig(
        provider: defaultConfig.provider,
        baseUrl: defaultConfig.baseUrl,
        apiKey: defaultConfig.apiKey,
        model: defaultConfig.model,
        active: config.active,
        isSystem: true,
        created: config.created,
        updated: DateTime.now(),
      );

      await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));
      setState(() {});

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '模型配置已重置到默认内容'
                  : 'Model configuration has been reset to default content',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[LLMConfigPage] 重置模型配置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '重置模型配置失败: $e'
                  : 'Failed to reset model configuration: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMissingSystemConfigs() async {
    try {
      final createdCount = await AppConfigService.createMissingSystemLlmConfigs();

      if (createdCount > 0) {
        // 重新加载配置列表
        await _loadConfigs();

        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'zh'
                    ? '成功重置了 $createdCount 个系统模型配置'
                    : 'Successfully reset $createdCount system model configurations',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 显示没有缺少的配置消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'zh'
                    ? '所有系统模型配置都已存在'
                    : 'All system model configurations already exist',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('[LLMConfigPage] 重置系统模型配置失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '重置系统模型配置失败: $e'
                  : 'Failed to reset system model configurations: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.backgroundGradient,
        ),
      ),
      child: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // 页面标题
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.smart_toy, color: context.primaryTextColor, size: 24), // 使用AI机器人图标
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.llmManage,
                            style: TextStyle(
                              fontSize: SettingsUiConfig.titleFontSize,
                              fontWeight: SettingsUiConfig.titleFontWeight,
                              color: context.primaryTextColor,
                            ),
                          ),
                          const Spacer(),
                          // 重置系统模型按钮
                          IconButton(
                            icon: Icon(Icons.refresh, color: context.primaryTextColor, size: 20),
                            onPressed: _createMissingSystemConfigs,
                            tooltip: Localizations.localeOf(context).languageCode == 'zh'
                                ? '重置系统默认模型'
                                : 'Reset System Default Models',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _configs.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.llmNone,
                                style: TextStyle(color: context.secondaryTextColor, fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _configs.length,
                              itemBuilder: (ctx, i) {
                                final c = _configs[i];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.cardBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: context.borderColor, width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      onTap: () => _showEditDialog(config: c, index: i, readOnly: false),
                                      leading: IconButton(
                                        icon: Icon(
                                          c.active ? Icons.check_circle : Icons.circle_outlined,
                                          color: c.active ? Colors.green : context.secondaryTextColor,
                                          size: 22,
                                        ),
                                        onPressed: () => _setActive(i),
                                        tooltip: AppLocalizations.of(context)!.llmSetActive,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.provider,
                                            style: TextStyle(
                                              fontSize: SettingsUiConfig.subtitleFontSize,
                                              color: context.secondaryTextColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c.model,
                                                  style: TextStyle(
                                                    fontSize: SettingsUiConfig.titleFontSize,
                                                    color: context.primaryTextColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                              // 系统级配置角标
                                              if (c.isSystem)
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                                  ),
                                                  child: Text(
                                                    Localizations.localeOf(context).languageCode == 'zh'
                                                        ? '系统'
                                                        : 'System',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.blue,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Spacer(),
                                              IconButton(
                                                icon: Icon(Icons.copy, size: 20, color: context.secondaryTextColor),
                                                onPressed: () {
                                                  final copy = LLMConfig(
                                                    provider: c.provider,
                                                    baseUrl: c.baseUrl,
                                                    apiKey: c.apiKey,
                                                    model: c.model,
                                                    active: false, // 复制的配置默认为非激活
                                                    isSystem: false, // 复制的配置不是系统级
                                                    created: c.created,
                                                    updated: DateTime.now(),
                                                  );
                                                  _showEditDialog(config: copy);
                                                },
                                                tooltip: AppLocalizations.of(context)!.llmCopy,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              // 系统配置显示编辑和重置按钮，非系统配置只显示编辑按钮
                                              if (c.isSystem) ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: Icon(Icons.edit, size: 20, color: context.secondaryTextColor),
                                                  onPressed: () => _showEditDialog(config: c, index: i),
                                                  tooltip: AppLocalizations.of(context)!.llmEdit,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: Icon(Icons.refresh, size: 20, color: Colors.orange),
                                                  onPressed: () => _resetConfig(i),
                                                  tooltip: Localizations.localeOf(context).languageCode == 'zh'
                                                      ? '重置到默认'
                                                      : 'Reset to Default',
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ] else ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: Icon(Icons.edit, size: 20, color: context.secondaryTextColor),
                                                  onPressed: () => _showEditDialog(config: c, index: i),
                                                  tooltip: AppLocalizations.of(context)!.llmEdit,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                  color: c.isSystem ? Colors.red.withOpacity(0.5) : Colors.red,
                                                ),
                                                onPressed: c.isSystem ? null : () => _deleteConfig(i),
                                                tooltip: c.isSystem
                                                    ? (Localizations.localeOf(context).languageCode == 'zh'
                                                          ? '系统配置不可删除'
                                                          : 'System configuration cannot be deleted')
                                                    : AppLocalizations.of(context)!.llmDelete,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(Icons.play_arrow, size: 20, color: Colors.green),
                                                onPressed: () => _testConfig(i),
                                                tooltip: Localizations.localeOf(context).languageCode == 'zh'
                                                    ? '测试模型'
                                                    : 'Test Model',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: null,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      heroTag: 'add-model',
                      onPressed: () => _showEditDialog(),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      tooltip: AppLocalizations.of(context)!.llmAdd,
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
