import 'dart:io';
import 'package:flutter/material.dart';
import '../model/enums.dart';
import '../util/prompt_util.dart';
import '../model/prompt_config.dart';
import '../config/config_service.dart';
import '../generated/l10n/app_localizations.dart';

class PromptEditPage extends StatefulWidget {
  final FileSystemEntity? file;
  final PromptCategory activeCategory;
  final bool readOnly;
  final String? initialContent;
  final String? initialName; // 新增
  final bool isSystem; // 新增：是否为系统级提示词

  const PromptEditPage({
    super.key,
    this.file,
    required this.activeCategory,
    this.readOnly = false,
    this.initialContent,
    this.initialName, // 新增
    this.isSystem = false, // 新增
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

    // 使用传入的 isSystem 参数
    _isSystem = widget.isSystem;

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
        orElse: () => PromptConfig(name: '', type: type, content: ''),
      ),
    );
    setState(() {
      _contentCtrl.text = activePrompt.content;
      _nameCtrl.text = activePrompt.name;
      _selectedCategory = activePrompt.type;
      _isActive = activePrompt.active;
      _isSystem = activePrompt.isSystem; // 确保系统级标识正确加载
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePrompt() async {
    final name = _nameCtrl.text.trim().isEmpty
        ? 'prompt_${DateTime.now().millisecondsSinceEpoch}'
        : _nameCtrl.text.trim();
    final prompt = PromptConfig(
      name: name,
      type: _selectedCategory,
      active: _isActive,
      content: _contentCtrl.text,
      isSystem: _isSystem, // 保持原有的系统级标识
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.file == null
              ? AppLocalizations.of(context)!.promptEditAddTitle
              : AppLocalizations.of(context)!.promptEditEditTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.promptEditRoleName),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PromptCategory>(
              value: _selectedCategory,
              items: PromptCategory.values
                  .map(
                    (category) => DropdownMenuItem<PromptCategory>(
                      value: category,
                      child: Text(promptCategoryToDisplayName(category, context)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.promptEditCategory),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _isActive,
                  onChanged: (v) {
                          setState(() => _isActive = v ?? false);
                        },
                ),
                Text(AppLocalizations.of(context)!.promptEditSetActive),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.promptEditContent,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _savePrompt,
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.promptEditSave),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
