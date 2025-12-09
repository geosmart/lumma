import 'package:flutter/material.dart';
import 'package:lumma/dao/diary_dao.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';

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
      final files = await DiaryDao.listDiaryFiles();
      // Sort by filename in descending order (YYYY-MM-DD.md format)
      files.sort((a, b) {
        final dateA = _extractDateFromFilename(a);
        final dateB = _extractDateFromFilename(b);

        if (dateA == null && dateB == null) return b.compareTo(a); // Fallback to alphabetical desc
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA); // Descending order by date
      });

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.loadDiaryFilesFailed}: ${e.toString()}')));
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
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await DiaryDao.deleteDiaryFile(file);
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteSuccess)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.deleteFailed}: ${e.toString()}')));
      }
    }
  }

  void _onCreate() async {
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      // 生成日期格式的文件名，格式为 YYYY-MM-DD.md
      final fileName =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}.md';

      try {
        await DiaryDao.createDiaryFile(fileName);
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.createSuccess)));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.createFailed}: ${e.toString()}')));
      }
    }
  }

  /// Extract date from filename (YYYY-MM-DD.md format)
  DateTime? _extractDateFromFilename(String filename) {
    try {
      // Remove .md extension if present
      final nameWithoutExt = filename.endsWith('.md') ? filename.substring(0, filename.length - 3) : filename;

      // Check if filename matches YYYY-MM-DD format
      final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
      if (!dateRegex.hasMatch(nameWithoutExt)) {
        return null;
      }

      // Parse the date
      final parts = nameWithoutExt.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
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
            IconButton(icon: const Icon(Icons.add), tooltip: l10n.newDiaryTooltip, onPressed: _onCreate),
          ],
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (!_loading)
          ..._files.map(
            (f) => ListTile(
              title: Text(f),
              onTap: () => _onTap(f),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _onDelete(f),
              ),
            ),
          ),
      ],
    );
  }
}

// This file has been replaced by DiaryFileManager, keeping empty shell to prevent import errors, can be safely deleted.
