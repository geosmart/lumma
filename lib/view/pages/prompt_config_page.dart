import 'package:flutter/material.dart';
import 'package:lumma/service/prompt_config_service.dart';
import 'package:lumma/model/enums.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/view/pages/prompt_edit_page.dart';
import 'package:lumma/config/settings_ui_config.dart';
import 'package:lumma/util/prompt_util.dart';
import 'package:lumma/model/prompt_config.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';

class PromptConfigPage extends StatefulWidget {
  const PromptConfigPage({super.key});

  @override
  State<PromptConfigPage> createState() => _PromptConfigPageState();
}

class _PromptConfigPageState extends State<PromptConfigPage> {
  List<PromptConfig> _allPrompts = [];
  PromptCategory _activeCategory = PromptCategory.chat;
  Map<PromptCategory, String?> _activePrompt = {};

  @override
  void initState() {
    super.initState();
    _loadPrompts();
    _loadActivePrompt();
  }

  Future<void> _loadActivePrompt() async {
    // 获取当前激活 prompt 文件名
    try {
      final name = await getActivePromptName(_activeCategory); // 用名称
      setState(() {
        _activePrompt = {_activeCategory: name};
      });
      print('[PromptConfigPage] 当前 \\${promptCategoryToString(_activeCategory)} 类型的激活文件: \\${name ?? 'null'}');
    } catch (e) {
      print('[PromptConfigPage] 加载激活提示词失败: $e');
    }
  }

  Future<void> _loadPrompts() async {
    // 如果没有提示词，先初始化
    await PromptConfigService.init();
    // 加载所有prompt
    final prompts = await listPrompts();
    setState(() {
      _allPrompts = prompts;
    });
  }

  Future<List<PromptConfig>> _filteredPrompts() async {
    final filtered = _allPrompts.where((p) => p.type == _activeCategory).toList();

    // 排序：激活的提示词排在最前面，然后按创建时间降序排列
    filtered.sort((a, b) {
      final aActive = _activePrompt[_activeCategory] == a.name;
      final bActive = _activePrompt[_activeCategory] == b.name;

      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      // 如果都是激活或都不是激活，按创建时间降序排列
      final aCreated = a.created;
      final bCreated = b.created;
      return bCreated.compareTo(aCreated);
    });

    return filtered;
  }

  void _showPrompt(PromptConfig? prompt, {bool readOnly = false, String? initialContent}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PromptEditPage(
          file: null,
          activeCategory: _activeCategory,
          readOnly: readOnly,
          initialContent: prompt?.content ?? initialContent,
          initialName: prompt?.name, // 新增，传递名称
          isSystem: prompt?.isSystem ?? false, // 新增，传递系统级标识
        ),
      ),
    );
    if (result == true) {
      await _loadPrompts();
      await _loadActivePrompt();
    }
  }

  void _resetPrompt(PromptConfig prompt) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm),
        content: Text(AppLocalizations.of(context)!.promptResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.promptCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.promptReset),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 重置提示词
      await PromptConfigService.resetPrompt(prompt);

      // 重新加载提示词列表
      await _loadPrompts();
      await _loadActivePrompt();

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '提示词已重置到默认内容'
                  : 'Prompt has been reset to default content',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[PromptConfigPage] 重置提示词失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '重置提示词失败: $e'
                  : 'Failed to reset prompt: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createMissingSystemPrompts() async {
    try {
      final createdCount = await PromptConfigService.createMissingSystemPrompts();

      if (createdCount > 0) {
        // 重新加载提示词列表
        await _loadPrompts();
        await _loadActivePrompt();

        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'zh'
                    ? '成功创建了 $createdCount 个系统提示词'
                    : 'Successfully created $createdCount system prompts',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 显示没有缺少的提示词消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).languageCode == 'zh'
                    ? '所有系统提示词都已存在'
                    : 'All system prompts already exist',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('[PromptConfigPage] 创建系统提示词失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '创建系统提示词失败: $e'
                  : 'Failed to create system prompts: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyPrompt(PromptConfig prompt) async {
    try {
      final newPrompt = await PromptConfigService.copyPrompt(prompt);

      // 重新加载提示词列表
      await _loadPrompts();
      await _loadActivePrompt();

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '已复制提示词: ${newPrompt.name}'
                  : 'Copied prompt: ${newPrompt.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('[PromptConfigPage] 复制提示词失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh' ? '复制提示词失败: $e' : 'Failed to copy prompt: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deletePrompt(PromptConfig prompt) async {
    // 系统级提示词不可删除
    if (prompt.isSystem) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.promptSystemNotDeletable)));
      return;
    }
    // 检查是否为激活中的提示词
    final activeContent = await getActivePromptContent(_activeCategory);
    final isActivePrompt = prompt.content == activeContent;
    // 删除prompt
    await deletePrompt(prompt.type, prompt.name);
    // 如果删除的是激活中的提示词，需要重新设置激活项
    if (isActivePrompt) {
      final remainingPrompts = await listPrompts(category: _activeCategory);
      if (remainingPrompts.isNotEmpty) {
        final firstPrompt = remainingPrompts.first;
        await setActivePrompt(_activeCategory, firstPrompt.name);
      }
    }
    // 重新加载提示词列表和激活状态
    await _loadPrompts();
    await _loadActivePrompt();
  }

  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
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
      child: Column(
        children: [
          // 页面标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.person, color: context.primaryTextColor, size: 24), // 使用人物角色图标
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.promptManage,
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
                const Spacer(),
                // 创建系统提示词按钮
                IconButton(
                  icon: Icon(Icons.refresh, color: context.primaryTextColor, size: 20),
                  onPressed: _createMissingSystemPrompts,
                  tooltip: Localizations.localeOf(context).languageCode == 'zh'
                      ? '创建缺少的系统提示词'
                      : 'Create Missing System Prompts',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final category in PromptCategory.values)
                        ChoiceChip(
                          label: Text(promptCategoryToDisplayName(category, context)),
                          selected: _activeCategory == category,
                          onSelected: (v) {
                            setState(() {
                              _activeCategory = category;
                            });
                            _loadActivePrompt();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PromptConfig>>(
              future: _filteredPrompts(),
              builder: (context, snapshot) {
                final filtered = snapshot.data ?? [];
                return Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final prompt = filtered[i];
                        final name = prompt.name;
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
                              onTap: prompt.isSystem ? () => _showPrompt(prompt, readOnly: true) : () => _showPrompt(prompt),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 第一排：激活按钮+提示词名称
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _activePrompt[_activeCategory] ==
                                                  prompt
                                                      .name // 用名称判断激活
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: _activePrompt[_activeCategory] == prompt.name
                                              ? Colors.green
                                              : context.secondaryTextColor,
                                          size: 22,
                                        ),
                                        onPressed: () async {
                                          print('[PromptConfigPage] 尝试设置激活提示词: $_activeCategory -> ${prompt.name}');
                                          try {
                                            await setActivePrompt(_activeCategory, prompt.name);
                                            print('[PromptConfigPage] 设置激活提示词成功');
                                            await _loadActivePrompt();
                                            setState(() {});
                                          } catch (e) {
                                            print('[PromptConfigPage] 设置激活提示词失败: $e');
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)!.promptSetActiveFailed(e.toString()),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        tooltip: AppLocalizations.of(context)!.promptSetActive,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: SettingsUiConfig.titleFontSize,
                                                  color: context.primaryTextColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                            // 系统级提示词角标
                                            if (prompt.isSystem)
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
                                      ),
                                    ],
                                  ),
                                  // 第二排：创建时间 + 操作按钮
                                  Row(
                                    children: [
                                      // 创建时间
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 46, top: 2),
                                          child: Text(
                                            '${Localizations.localeOf(context).languageCode == 'zh' ? '创建时间: ' : 'Created: '}${_formatDateTime(prompt.created)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.secondaryTextColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // 操作按钮
                                      // 系统提示词：显示复制和重置按钮
                                      if (prompt.isSystem) ...[
                                        IconButton(
                                          icon: Icon(Icons.copy, size: 20, color: context.secondaryTextColor),
                                          onPressed: () async {
                                            await _copyPrompt(prompt);
                                          },
                                          tooltip: AppLocalizations.of(context)!.promptCopy,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.refresh, size: 20, color: Colors.orange),
                                          onPressed: () => _resetPrompt(prompt),
                                          tooltip: AppLocalizations.of(context)!.promptReset,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ] else ...[
                                        // 非系统提示词：显示复制和删除按钮
                                        IconButton(
                                          icon: Icon(Icons.copy, size: 20, color: context.secondaryTextColor),
                                          onPressed: () async {
                                            await _copyPrompt(prompt);
                                          },
                                          tooltip: AppLocalizations.of(context)!.promptCopy,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        // 删除按钮
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 20, color: Colors.red),
                                          onPressed: () => _deletePrompt(prompt),
                                          tooltip: AppLocalizations.of(context)!.promptDelete,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: null,
                            ), // End of ListTile
                          ), // End of Padding
                        ); // End of Container
                      },
                    ),
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: FloatingActionButton(
                          heroTag: 'add-prompt',
                          onPressed: () => _showPrompt(null),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          tooltip: AppLocalizations.of(context)!.promptAdd,
                          child: const Icon(Icons.add, size: 28),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
