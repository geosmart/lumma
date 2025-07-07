import 'package:flutter/material.dart';
import '../util/markdown_service.dart';
import '../generated/l10n/app_localizations.dart';

/// Diary file list component for managing diary files (create, read, update, delete)
class DiaryFileListWidget extends StatefulWidget {
  final void Function(String fileName)? onFileSelected;
  const DiaryFileListWidget({super.key, this.onFileSelected});

  @override
  State<DiaryFileListWidget> createState() => _DiaryFileListWidgetState();
}

class _DiaryFileListWidgetState extends State<DiaryFileListWidget> {
  List<String> _files = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final files = await MarkdownService.listDiaryFiles();
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _files = [];
        _loading = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.loadDiaryFilesFailed}: ${e.toString()}')),
      );
    }
  }

  void _onTap(String file) {
    widget.onFileSelected?.call(file);
  }

  void _onDelete(String file) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteFile(file)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await MarkdownService.deleteDiaryFile(file);
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteSuccess)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.deleteFailed}: ${e.toString()}')),
        );
      }
    }
  }

  void _onCreate() async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final fileName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newDiary),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(hintText: l10n.enterNewDiaryName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: Text(l10n.create)),
        ],
      ),
    );
    if (fileName != null && fileName.isNotEmpty) {
      try {
        await MarkdownService.createDiaryFile(fileName);
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.createSuccess)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.createFailed}: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.diaryFiles, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: l10n.newDiaryTooltip,
              onPressed: _onCreate,
            ),
          ],
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        if (!_loading)
          ..._files.map((f) => ListTile(
                title: Text(f),
                onTap: () => _onTap(f),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _onDelete(f),
                ),
              )),
      ],
    );
  }
}

// This file has been replaced by DiaryFileManager, keeping empty shell to prevent import errors, can be safely deleted.
