import 'dart:io';
import 'package:flutter/material.dart';
import '../services/prompt_service.dart';

class PromptEditPage extends StatefulWidget {
  final FileSystemEntity? file;
  final String activeCategory;

  const PromptEditPage({super.key, this.file, required this.activeCategory});

  @override
  State<PromptEditPage> createState() => _PromptEditPageState();
}

class _PromptEditPageState extends State<PromptEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _contentCtrl;
  late String _selectedCategory;
  late bool _isActive;
  bool _isSystem = false;

  final Map<String, String> _categoryNames = {
    'qa': '问答',
    'summary': '总结',
  };

  @override
  void initState() {
    super.initState();
    _isSystem = widget.file?.path.split('/').last == '问答AI日记助手.md';
    _contentCtrl = TextEditingController();
    _nameCtrl = TextEditingController();
    _selectedCategory = widget.activeCategory;
    _isActive = false;

    if (widget.file != null) {
      _loadPromptData();
    }
  }

  Future<void> _loadPromptData() async {
    final content = await File(widget.file!.path).readAsString();
    final meta = await PromptService.getPromptFrontmatter(File(widget.file!.path));
    setState(() {
      _contentCtrl.text = content;
      _nameCtrl.text = widget.file!.path.split('/').last.replaceAll('.md', '');
      _selectedCategory = meta['type'] ?? widget.activeCategory;
      _isActive = meta['active'] == true || meta['active'] == 'true';
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    final name = _nameCtrl.text.trim().isEmpty ? 'prompt_${DateTime.now().millisecondsSinceEpoch}' : _nameCtrl.text.trim();
    await PromptService.savePrompt(
      fileName: '$name.md',
      content: _contentCtrl.text,
      type: _selectedCategory,
      oldFileName: widget.file?.path.split('/').last,
    );
    if (_isActive) {
      await PromptService.setActivePrompt(_selectedCategory, '$name.md');
    }
    if (mounted) {
       Navigator.of(context).pop(true); // Return true to indicate save
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file == null ? '新建提示词' : _isSystem ? '系统提示词' : '编辑提示词'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '角色名称/文件名'),
              readOnly: _isSystem,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categoryNames.entries
                  .map((e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: _isSystem
                  ? null
                  : (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
              decoration: const InputDecoration(labelText: '分类'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _isActive,
                  onChanged: _isSystem
                      ? null
                      : (v) {
                          setState(() => _isActive = v ?? false);
                        },
                ),
                const Text('设为激活'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Markdown 内容',
                  border: OutlineInputBorder(),
                ),
                readOnly: _isSystem,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _isSystem ? null : _savePrompt,
                icon: const Icon(Icons.save),
                label: const Text('保存'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
