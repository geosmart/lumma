import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lumma/config/prompt_config_service.dart';
import 'package:lumma/model/enums.dart';
import 'prompt_service.dart';
import 'theme_service.dart';
import 'prompt_edit_page.dart';
import 'settings_ui_config.dart';

class PromptConfigPage extends StatefulWidget {
  const PromptConfigPage({super.key});

  @override
  State<PromptConfigPage> createState() => _PromptConfigPageState();
}

class _PromptConfigPageState extends State<PromptConfigPage> {
  List<FileSystemEntity> _allPrompts = [];
  PromptCategory _activeCategory = PromptCategory.qa;
  Map<PromptCategory, String?> _activePrompt = {};

  @override
  void initState() {
    super.initState();
    _loadPrompts();
    _loadActivePrompt();
    _printPromptDir();
  }

  Future<void> _loadActivePrompt() async {
    // 获取当前激活 prompt 文件名
    try {
      final file = await PromptService.getActivePromptFile(_activeCategory);
      setState(() {
        _activePrompt = {_activeCategory: file?.path};
      });
      print('[PromptConfigPage] 当前 ${promptCategoryToString(_activeCategory)} 类型的激活文件: [38;5;2m${file?.path ?? 'null'}[0m');
    } catch (e) {
      print('[PromptConfigPage] 加载激活提示词失败: $e');
    }
  }

  Future<void> _loadPrompts() async {
    // 如果没有提示词，先初始化
    await PromptConfigService.init();

    // 加载所有提示词文件
    final files = await PromptService.listPrompts();
    setState(() {
      _allPrompts = files;
    });
  }

  Future<List<FileSystemEntity>> _filteredPrompts() async {
    List<FileSystemEntity> result = [];
    for (final f in _allPrompts) {
      final meta = await PromptService.getPromptFrontmatter(File(f.path));
      if ((meta['type'] ?? 'qa') == promptCategoryToString(_activeCategory)) {
        result.add(f);
      }
    }
    return result;
  }

  void _showPrompt(FileSystemEntity? file) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PromptEditPage(file: file, activeCategory: _activeCategory),
      ),
    );

    if (result == true) {
      await _loadPrompts();
      await _loadActivePrompt();
    }
  }

  void _deletePrompt(FileSystemEntity file) async {
    final name = file.path.split('/').last;

    // 系统默认提示词不可删除
    if (name == '问答AI日记助手.md' || name == '总结AI日记助手.md') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('系统提示词不可删除')));
      return;
    }

    // 检查是否为激活中的提示词
    final activeFile = await PromptService.getActivePromptFile(_activeCategory);
    final isActivePrompt = activeFile != null && activeFile.path == file.path;

    // 删除提示词文件
    await PromptService.deletePrompt(name);

    // 如果删除的是激活中的提示词，需要重新设置激活项
    if (isActivePrompt) {
      // 获取同类型的第一个提示词并设为激活
      final remainingFiles = await PromptService.listPrompts(category: _activeCategory);
      if (remainingFiles.isNotEmpty) {
        final firstFile = remainingFiles.first;
        final firstName = firstFile.path.split('/').last;
        await PromptService.setActivePrompt(_activeCategory, firstName);
      }
    }

    // 重新加载提示词列表和激活状态
    await _loadPrompts();
    await _loadActivePrompt();
  }

  Future<void> _printPromptDir() async {
    final dir = await PromptService.getPromptDir();
    print('[PromptConfigPage] 当前日记prompt存储目录: $dir');
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
            child: FutureBuilder<List<FileSystemEntity>>(
              future: _filteredPrompts(),
              builder: (context, snapshot) {
                final filtered = snapshot.data ?? [];
                return Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final file = filtered[i];
                        final name = file.path.split('/').last;
                        return FutureBuilder<Map<String, dynamic>>(
                          future: PromptService.getPromptFrontmatter(File(file.path)),
                          builder: (context, snapshot) {
                            String title = name;
                            // 显示文件名，与模型管理页样式一致
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
                                  leading: IconButton(
                                    icon: Icon(
                                      _activePrompt[_activeCategory] == file.path
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: _activePrompt[_activeCategory] == file.path ? Colors.green : context.secondaryTextColor,
                                      size: 22,
                                    ),
                                    onPressed: () async {
                                      final fileName = file.path.split('/').last;
                                      print('[PromptConfigPage] 尝试设置激活提示词: $_activeCategory -> $fileName');
                                      try {
                                        await PromptService.setActivePrompt(_activeCategory, fileName);
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
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        promptCategoryToDisplayName(_activeCategory),
                                        style: TextStyle(
                                          fontSize: SettingsUiConfig.subtitleFontSize,
                                          color: context.secondaryTextColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: SettingsUiConfig.titleFontSize,
                                          color: context.primaryTextColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy,
                                          size: 20,
                                          color: context.secondaryTextColor,
                                        ),
                                        onPressed: () => _showPrompt(file),
                                        tooltip: '复制',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8), // 添加间距
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: context.secondaryTextColor,
                                        ),
                                        onPressed: () => _showPrompt(file),
                                        tooltip: '编辑',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8), // 添加间距
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _deletePrompt(file),
                                        tooltip: '删除',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ), // End of ListTile
                              ), // End of Padding
                            ); // End of Container
                          },
                        );
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
                          child: const Icon(Icons.add, size: 28),
                          tooltip: '添加提示词',
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
