import 'dart:io';
import 'package:flutter/material.dart';
import '../services/markdown_service.dart';

class DiaryFileEditor extends StatefulWidget {
  final String fileName;
  final VoidCallback onSaved;

  const DiaryFileEditor({super.key, required this.fileName, required this.onSaved});

  @override
  State<DiaryFileEditor> createState() => _DiaryFileEditorState();
}

class _DiaryFileEditorState extends State<DiaryFileEditor> {
  final TextEditingController _editCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.fileName;
    _loadFileContent();
  }

  Future<void> _loadFileContent() async {
    final diaryDir = await MarkdownService.getDiaryDir();
    final f = File('$diaryDir/${widget.fileName}');
    if (await f.exists()) {
      _editCtrl.text = await f.readAsString();
    }
  }

  Future<void> _saveFile() async {
    setState(() => _saving = true);
    try {
      final newName = _nameCtrl.text.trim();
      final diaryDir = await MarkdownService.getDiaryDir();
      final oldFile = File('$diaryDir/${widget.fileName}');
      final newFile = File('$diaryDir/$newName');

      await oldFile.writeAsString(_editCtrl.text);
      if (newName != widget.fileName && newName.isNotEmpty) {
        await oldFile.rename(newFile.path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '文件名'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _editCtrl,
                  maxLines: 12,
                  decoration: InputDecoration(
                    labelText: widget.fileName,
                    border: const OutlineInputBorder(),
                    hintText: '编辑日记内容',
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
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: _saving ? const Text('保存中...') : const Text('保存'),
                    onPressed: _saving ? null : _saveFile,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }
}