import 'package:flutter/material.dart';
import 'package:lumma/config/prompt_config_service.dart';
import 'package:lumma/model/enums.dart';
import 'prompt_service.dart';
import 'theme_service.dart';
import 'prompt_edit_page.dart';
import 'settings_ui_config.dart';
import '../util/prompt_util.dart';
import '../model/prompt_config.dart';

class PromptConfigPage extends StatefulWidget {
  const PromptConfigPage({super.key});

  @override
  State<PromptConfigPage> createState() => _PromptConfigPageState();
}

class _PromptConfigPageState extends State<PromptConfigPage> {
  List<PromptConfig> _allPrompts = [];
  PromptCategory _activeCategory = PromptCategory.qa;
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
      final content = await getActivePromptContent(_activeCategory);
      setState(() {
        _activePrompt = {_activeCategory: content};
      });
      print('[PromptConfigPage] 当前 ${promptCategoryToString(_activeCategory)} 类型的激活文件: [38;5;2m${content ?? 'null'}[0m');
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
    return _allPrompts.where((p) => p.type == _activeCategory).toList();
  }

  void _showPrompt(PromptConfig? prompt, {bool readOnly = false, String? initialContent}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PromptEditPage(
          file: null,
          activeCategory: _activeCategory,
          readOnly: readOnly,
          initialContent: prompt?.content ?? initialContent,
        ),
      ),
    );
    if (result == true) {
      await _loadPrompts();
      await _loadActivePrompt();
    }
  }

  void _deletePrompt(PromptConfig prompt) async {
    // 系统默认提示词不可删除
    if (prompt.name == '问答AI日记助手.md' || prompt.name == '总结AI日记助手.md') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('系统提示词不可删除')));
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
                Icon(
                  Icons.chat,
                  color: context.primaryTextColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '提示词管理',
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
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
                          label: Text(promptCategoryToDisplayName(category)),
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
                            border: Border.all(
                              color: context.borderColor,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 第一排：激活按钮+提示词名称
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          _activePrompt[_activeCategory] == prompt.content
                                              ? Icons.check_circle
                                              : Icons.circle_outlined,
                                          color: _activePrompt[_activeCategory] == prompt.content ? Colors.green : context.secondaryTextColor,
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
                                                SnackBar(content: Text('设置激活失败: $e')),
                                              );
                                            }
                                          }
                                        },
                                        tooltip: '设为激活',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
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
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // 第二排：右下角3个操作按钮
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          size: 20,
                                          color: context.secondaryTextColor,
                                        ),
                                        onPressed: () async {
                                          _showPrompt(prompt);
                                        },
                                        tooltip: '复制',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: context.secondaryTextColor,
                                        ),
                                        onPressed: () => _showPrompt(prompt),
                                        tooltip: '编辑',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deletePrompt(prompt),
                                        tooltip: '删除',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
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
                          tooltip: '添加提示词',
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
