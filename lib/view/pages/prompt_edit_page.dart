import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lumma/model/enums.dart';
import 'package:lumma/util/prompt_util.dart';
import 'package:lumma/model/prompt_config.dart';
import 'package:lumma/config/prompt_constants.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';

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
    _isActive = false; // 默认不激活

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

  Future<void> _resetPrompt() async {
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
      // 获取默认内容
      String defaultContent;

      if (_isSystem) {
        // 系统级提示词：根据名称精确匹配
        final systemChatPrompts = PromptConstants.getSystemChatPrompts();
        final matchingSystemPrompt = systemChatPrompts.firstWhere(
          (prompt) => _nameCtrl.text.contains(prompt['name']!),
          orElse: () => <String, String>{},
        );

        if (matchingSystemPrompt.isNotEmpty) {
          // 找到匹配的系统聊天提示词
          defaultContent = matchingSystemPrompt['content']!;
        } else {
          // 没有找到匹配的系统聊天提示词，使用默认类型内容
          switch (_selectedCategory) {
            case PromptCategory.chat:
              defaultContent = PromptConstants.getDefaultChatPrompt();
              break;
            case PromptCategory.summary:
              defaultContent = PromptConstants.getDefaultSummaryPrompt();
              break;
            case PromptCategory.correction:
              defaultContent = PromptConstants.getDefaultCorrectionPrompt();
              break;
          }
        }
      } else {
        // 非系统级提示词：使用默认类型内容
        switch (_selectedCategory) {
          case PromptCategory.chat:
            defaultContent = PromptConstants.getDefaultChatPrompt();
            break;
          case PromptCategory.summary:
            defaultContent = PromptConstants.getDefaultSummaryPrompt();
            break;
          case PromptCategory.correction:
            defaultContent = PromptConstants.getDefaultCorrectionPrompt();
            break;
        }
      }

      // 重置内容
      setState(() {
        _contentCtrl.text = defaultContent;
      });

      // 显示重置成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh'
                  ? '提示词已重置到默认内容'
                  : 'Prompt has been reset to default content',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[PromptEditPage] 重置提示词失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Localizations.localeOf(context).languageCode == 'zh' ? '重置提示词失败: $e' : 'Failed to reset prompt: $e',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
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
              readOnly: _isSystem, // 系统级提示词不允许修改名称
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PromptCategory>(
              initialValue: _selectedCategory,
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
            // 显示重置按钮
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton.icon(
                onPressed: _resetPrompt,
                icon: const Icon(Icons.person_outline), // 使用人物角色图标
                label: Text(Localizations.localeOf(context).languageCode == 'zh' ? '重置到默认' : 'Reset to Default'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _savePrompt,
                icon: const Icon(Icons.person_add), // 使用添加人物角色图标
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
