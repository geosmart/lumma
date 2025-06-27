import 'dart:io';
import 'package:flutter/material.dart';
import '../services/prompt_service.dart';

class PromptConfigPage extends StatefulWidget {
  const PromptConfigPage({super.key});

  @override
  State<PromptConfigPage> createState() => _PromptConfigPageState();
}

class _PromptConfigPageState extends State<PromptConfigPage> {
  List<FileSystemEntity> _prompts = [];
  List<FileSystemEntity> _allPrompts = [];
  bool _loading = true;
  String _activeCategory = 'qa';
  Map<String, String?> _activePrompt = {};

  @override
  void initState() {
    super.initState();
    _initDefaultPrompt();
    _loadPrompts();
    _loadActivePrompt();
    _printPromptDir();
  }

  Future<void> _initDefaultPrompt() async {
    final files = await PromptService.listPrompts();
    final defaultName = '问答AI日记助手.md';
    if (!files.any((f) => f.path.split('/').last == defaultName)) {
      final dir = await PromptService.getPromptDir();
      final f = File('$dir/$defaultName');
      final now = DateTime.now().toIso8601String();
      await f.writeAsString('''---
type: qa
created: $now
updated: $now
active: true
---
你是一个专业、灵活的“AI 日记伙伴”。你的核心任务是倾听我用自然语言（通常是语音输入）自由地讲述今天发生的事情和感受，并智能地将这些零散的信息整理成一份结构化的日记。

#### 核心能力
1. 自动纠错：你能自动识别并修正我语音输入时产生的错别字、同音字和语法错误，理解口语化的表达。
2. 意图识别与归类：你拥有强大的内容理解能力。我不需要说出标签，你能根据我描述的事情和感受，自动判断它属于哪个日记分类（如 #环境, #成就, #情绪 等）。一件事可能同时属于多个分类。
3. 非线性处理：你完全理解我不会按顺序讲述。我可以随时谈论任何主题，你可以接收、暂存并最终将所有信息整合在一起。
''');
    }
  }

  Future<void> _loadActivePrompt() async {
    // 获取当前激活 prompt 文件名
    final file = await PromptService.getActivePromptFile(_activeCategory);
    setState(() {
      _activePrompt = {_activeCategory: file?.path};
    });
  }

  Future<void> _loadPrompts() async {
    final files = await PromptService.listPrompts();
    _allPrompts = files;
    setState(() {
      _prompts = files;
      _loading = false;
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
    'qa': '日记问答',
    'correction': '纠错',
    'summary': '总结',
    'markdown': 'markdown格式化',
  };

  void _showPrompt(FileSystemEntity? file) async {
    final isSystem = file?.path.split('/').last == '问答AI日记助手.md';
    final content = file == null ? '' : await File(file.path).readAsString();
    final meta = file == null ? {} : await PromptService.getPromptFrontmatter(File(file.path));
    final ctrl = TextEditingController(text: content);
    final nameCtrl = TextEditingController(text: file?.path.split('/').last.replaceAll('.md', '') ?? '');
    String selectedCategory = meta['type'] ?? _activeCategory;
    bool isActive = meta['active'] == true || meta['active'] == 'true';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(file == null ? '新建提示词' : isSystem ? '系统提示词' : '编辑提示词'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '角色名称/文件名'),
              enabled: !isSystem,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: _categoryNames.entries
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: isSystem ? null : (v) {
                if (v != null) selectedCategory = v;
              },
              decoration: const InputDecoration(labelText: '分类'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: isActive,
                  onChanged: isSystem
                      ? null
                      : (v) {
                          isActive = v ?? false;
                        },
                ),
                const Text('设为激活'),
              ],
            ),
            TextField(
              controller: ctrl,
              maxLines: 12,
              decoration: const InputDecoration(labelText: 'Markdown 内容'),
              enabled: !isSystem,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          if (!isSystem)
            ElevatedButton(
              onPressed: () async {
                final userDir = await PromptService.getPromptDir();
                final name = nameCtrl.text.trim().isEmpty ? 'prompt_${DateTime.now().millisecondsSinceEpoch}' : nameCtrl.text.trim();
                final f = File('$userDir/$name.md');
                await PromptService.savePrompt(
                  fileName: '$name.md',
                  content: ctrl.text,
                  type: selectedCategory,
                  oldFileName: file?.path.split('/').last,
                );
                if (isActive) {
                  await PromptService.setActivePrompt(selectedCategory, '$name.md');
                }
                await _loadPrompts();
                await _loadActivePrompt();
                // ignore: use_build_context_synchronously
                Navigator.of(ctx).pop();
              },
              child: const Text('保存'),
            ),
        ],
      ),
    );
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
    return Column(
      children: [
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
                          final meta = snapshot.data ?? {};
                          String title = name;
                          // 只显示文件名，不再格式化为日期
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.chat_bubble_outline),
                              title: Text(title),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showPrompt(file),
                                    tooltip: '编辑',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deletePrompt(file),
                                    tooltip: '删除',
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _activePrompt[_activeCategory] == file.path
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: _activePrompt[_activeCategory] == file.path ? Colors.green : null,
                                    ),
                                    onPressed: () async {
                                      final fileName = file.path.split('/').last;
                                      await PromptService.setActivePrompt(_activeCategory, fileName);
                                      await _loadActivePrompt();
                                      setState(() {});
                                    },
                                    tooltip: '设为激活',
                                  ),
                                ],
                              ),
                              onTap: () => _showPrompt(file),
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
    );
  }
}
