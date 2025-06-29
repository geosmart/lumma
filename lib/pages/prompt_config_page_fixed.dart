import 'dart:io';
import 'package:flutter/material.dart';
import '../services/prompt_service.dart';
import '../services/theme_service.dart';
import 'prompt_edit_page.dart';
import '../config/settings_ui_config.dart';

class PromptConfigPage extends StatefulWidget {
  const PromptConfigPage({super.key});

  @override
  State<PromptConfigPage> createState() => _PromptConfigPageState();
}

class _PromptConfigPageState extends State<PromptConfigPage> {
  List<FileSystemEntity> _allPrompts = [];
  String _activeCategory = 'qa';
  Map<String, String?> _activePrompt = {};

  @override
  void initState() {
    super.initState();
    _initDefaultPrompts();
    _loadPrompts();
    _loadActivePrompt();
    _printPromptDir();
  }

  Future<void> _initDefaultPrompts() async {
    final files = await PromptService.listPrompts();
    final dir = await PromptService.getPromptDir();
    final now = DateTime.now().toIso8601String();

    // QA默认提示词
    final qaDefaultName = '问答AI日记助手.md';
    if (!files.any((f) => f.path.split('/').last == qaDefaultName)) {
      final f = File('$dir/$qaDefaultName');
      await f.writeAsString('''---
type: qa
created: $now
updated: $now
active: true
---
你是一个专业、灵活的"AI 日记伙伴"。你的核心任务是倾听我用自然语言（通常是语音输入）自由地讲述今天发生的事情和感受，并智能地将这些零散的信息整理成一份结构化的日记。

#### 核心能力
1. 自动纠错：你能自动识别并修正我语音输入时产生的错别字、同音字和语法错误，理解口语化的表达。
2. 意图识别与归类：你拥有强大的内容理解能力。我不需要说出标签，你能根据我描述的事情和感受，自动判断它属于哪个日记分类（如 #环境, #成就, #情绪 等）。一件事可能同时属于多个分类。
3. 非线性处理：你完全理解我不会按顺序讲述。我可以随时谈论任何主题，你可以接收、暂存并最终将所有信息整合在一起。
''');
    }

    // 总结默认提示词
    final summaryDefaultName = '内容总结助手.md';
    if (!files.any((f) => f.path.split('/').last == summaryDefaultName)) {
      final f = File('$dir/$summaryDefaultName');
      await f.writeAsString('''---
type: summary
created: $now
updated: $now
active: true
---
你是一个专业的内容总结助手。你的任务是：

1. **提取要点**：从长文本中提取关键信息和核心观点
2. **结构化总结**：按主题或时间线组织总结内容
3. **保持完整性**：确保总结涵盖原文的重要信息
4. **简洁明了**：用简练的语言表达核心内容

请对以下内容进行总结：
''');
    }
  }

  Future<void> _loadActivePrompt() async {
    // 获取当前激活 prompt 文件名
    try {
      final file = await PromptService.getActivePromptFile(_activeCategory);
      setState(() {
        _activePrompt = {_activeCategory: file?.path};
      });
      print('[PromptConfigPage] 当前 $_activeCategory 类型的激活文件: ${file?.path ?? 'null'}');
    } catch (e) {
      print('[PromptConfigPage] 加载激活提示词失败: $e');
    }
  }

  Future<void> _loadPrompts() async {
    final files = await PromptService.listPrompts();
    _allPrompts = files;
    setState(() {
      // 数据已加载完成
    });
  }

  Future<List<FileSystemEntity>> _filteredPrompts() async {
    List<FileSystemEntity> result = [];
    for (final f in _allPrompts) {
      final meta = await PromptService.getPromptFrontmatter(File(f.path));
      if ((meta['type'] ?? 'qa') == _activeCategory) {
        result.add(f);
      }
    }
    return result;
  }

  final Map<String, String> _categoryNames = {
    'qa': '问答',
    'summary': '总结',
  };

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
    if (name == '问答AI日记助手.md') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('系统提示词不可删除')));
      return;
    }
    await PromptService.deletePrompt(name);
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
                      for (final entry in _categoryNames.entries)
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _activeCategory == entry.key,
                          onSelected: (v) {
                            setState(() {
                              _activeCategory = entry.key;
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
                                        _categoryNames[_activeCategory] ?? '提示词',
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
                                ),
                              ),
                            );
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
