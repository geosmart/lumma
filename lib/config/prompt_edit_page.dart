import 'dart:io';
import 'package:flutter/material.dart';
import '../model/enums.dart';
import '../util/prompt_util.dart';
import '../model/prompt_config.dart';
import '../config/config_service.dart';

class PromptEditPage extends StatefulWidget {
  final FileSystemEntity? file;
  final PromptCategory activeCategory;
  final bool readOnly;
  final String? initialContent;
  final String? initialName; // 新增

  const PromptEditPage({
    super.key,
    this.file,
    required this.activeCategory,
    this.readOnly = false,
    this.initialContent,
    this.initialName, // 新增
  });

  @override
  State<PromptEditPage> createState() => _PromptEditPageState();
}

class _PromptEditPageState extends State<PromptEditPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _contentCtrl;
  late PromptCategory _selectedCategory;
  late bool _isActive;
  bool _isSystem = false;

  @override
  void initState() {
    super.initState();
    _isSystem = widget.file?.path.split('/').last == '问答AI日记助手.md';
    _contentCtrl = TextEditingController(text: widget.initialContent ?? '');
    _nameCtrl = TextEditingController(text: widget.initialName ?? ''); // 优先用 initialName
    _selectedCategory = widget.activeCategory;
    _isActive = false;

    if (widget.file != null) {
      _loadPromptData();
    }
  }

  Future<void> _loadPromptData() async {
    final config = await AppConfigService.load();
    final type = widget.activeCategory;
    // 优先找active的
    final activePrompt = config.prompt.firstWhere(
      (p) => p.type == type && p.active,
      orElse: () => config.prompt.firstWhere(
        (p) => p.type == type,
        orElse: () => PromptConfig(
          name: '',
          type: type,
          content: '',
        ),
      ),
    );
    setState(() {
      _contentCtrl.text = activePrompt.content;
      _nameCtrl.text = activePrompt.name;
      _selectedCategory = activePrompt.type;
      _isActive = activePrompt.active;
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
    final prompt = PromptConfig(
      name: name,
      type: _selectedCategory,
      active: _isActive,
      content: _contentCtrl.text,
      updated: DateTime.now(),
    );
    await savePrompt(prompt, oldName: widget.file?.path.split('/').last.replaceAll('.md', ''));
    if (_isActive) {
      await setActivePrompt(_selectedCategory, name);
    }
    if (mounted) {
       Navigator.of(context).pop(true); // Return true to indicate save
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isReadOnly = widget.readOnly || _isSystem;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file == null ? '新建提示词' : _isSystem ? '系统提示词' : (widget.readOnly ? '查看提示词' : '编辑提示词')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '角色名称/文件名'),
              readOnly: isReadOnly,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PromptCategory>(
              value: _selectedCategory,
              items: PromptCategory.values
                  .map((category) => DropdownMenuItem<PromptCategory>(
                        value: category,
                        child: Text(promptCategoryToDisplayName(category)),
                      ))
                  .toList(),
              onChanged: isReadOnly
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
                  onChanged: isReadOnly
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
                readOnly: isReadOnly,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: isReadOnly ? null : _savePrompt,
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
