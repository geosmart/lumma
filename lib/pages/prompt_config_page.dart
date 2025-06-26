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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initDefaultPrompt();
    _loadPrompts();
  }

  Future<void> _initDefaultPrompt() async {
    final files = await PromptService.listPrompts();
    final defaultName = '问答AI日记助手.md';
    if (!files.any((f) => f.path.split('/').last == defaultName)) {
      final dir = await PromptService.getPromptDir();
      final f = File('$dir/$defaultName');
      await f.writeAsString('''你是一个专业、灵活的“AI 日记伙伴”。你的核心任务是倾听我用自然语言（通常是语音输入）自由地讲述今天发生的事情和感受，并智能地将这些零散的信息整理成一份结构化的日记。

#### 核心能力
1. 自动纠错：你能自动识别并修正我语音输入时产生的错别字、同音字和语法错误，理解口语化的表达。
2. 意图识别与归类：你拥有强大的内容理解能力。我不需要说出标签，你能根据我描述的事情和感受，自动判断它属于哪个日记分类（如 #环境, #成就, #情绪 等）。一件事可能同时属于多个分类。
3. 非线性处理：你完全理解我不会按顺序讲述。我可以随时谈论任何主题，你可以接收、暂存并最终将所有信息整合在一起。
''');
    }
  }

  Future<void> _loadPrompts() async {
    final files = await PromptService.listPrompts();
    setState(() {
      _prompts = files;
      _loading = false;
    });
  }

  void _showPrompt(FileSystemEntity? file) async {
    final isSystem = file?.path.split('/').last == '问答AI日记助手.md';
    final content = file == null ? '' : await File(file.path).readAsString();
    final ctrl = TextEditingController(text: content);
    final nameCtrl = TextEditingController(text: file?.path.split('/').last.replaceAll('.md', '') ?? '');
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
                await f.writeAsString(ctrl.text);
                await _loadPrompts();
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
    await File(file.path).delete();
    await _loadPrompts();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _prompts.length,
          itemBuilder: (ctx, i) {
            final file = _prompts[i];
            final name = file.path.split('/').last;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(name),
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
                  ],
                ),
                onTap: () => _showPrompt(file),
              ),
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
  }
}
