import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dao/diary_dao.dart';
import '../generated/l10n/app_localizations.dart';

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
    final diaryDir = await DiaryDao.getDiaryDir();
    final f = File('$diaryDir/${widget.fileName}');
    if (await f.exists()) {
      _editCtrl.text = await f.readAsString();
    }
  }

  Future<void> _saveFile() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      final newName = _nameCtrl.text.trim();
      final diaryDir = await DiaryDao.getDiaryDir();
      final oldFile = File('$diaryDir/${widget.fileName}');
      final newFile = File('$diaryDir/$newName');

      await oldFile.writeAsString(_editCtrl.text);
      if (newName != widget.fileName && newName.isNotEmpty) {
        await oldFile.rename(newFile.path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveSuccess)));
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.saveFailed}: ${e.toString()}')));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  decoration: InputDecoration(labelText: l10n.fileName),
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    TextField(
                      controller: _editCtrl,
                      maxLines: 12,
                      decoration: InputDecoration(
                        labelText: widget.fileName,
                        border: const OutlineInputBorder(),
                        hintText: l10n.editDiaryContent,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: l10n.copy,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _editCtrl.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已复制'), duration: const Duration(milliseconds: 800)),
                          );
                        },
                      ),
                    ),
                  ],
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
                    label: _saving ? Text(l10n.saving) : Text(l10n.save),
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
