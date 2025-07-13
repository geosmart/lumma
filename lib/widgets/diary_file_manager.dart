import 'dart:io';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../dao/diary_dao.dart';
import '../util/diary_frontmatter_util.dart';
import '../config/theme_service.dart';
import '../diary/diary_content_page.dart';

/// Diary file management component, integrating list, CRUD operations, editing, selection, and other functionalities
class DiaryFileManager extends StatefulWidget {
  /// Callback after selecting a file (optional)
  final void Function(String fileName)? onFileSelected;
  const DiaryFileManager({super.key, this.onFileSelected});

  @override
  State<DiaryFileManager> createState() => _DiaryFileManagerState();
}

class _DiaryFileManagerState extends State<DiaryFileManager> {
  List<String> _files = [];
  bool _loading = false;
  final TextEditingController _editCtrl = TextEditingController();

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
      // This is more efficient than reading frontmatter for each file
      files.sort((a, b) {
        // Extract date from filename for comparison
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.loading}${AppLocalizations.of(context)!.noFilesFound}: ${e.toString()}',
          ),
        ),
      );
    }
  }

  Future<void> _deleteFile(String file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
        content: Text('${AppLocalizations.of(context)!.deleteConfirmMessage} "$file"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DiaryDao.deleteDiaryFile(file);
      await _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.delete} ${AppLocalizations.of(context)!.ok}')),
        );
      }
    }
  }

  Future<void> _createFile() async {
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

      print('Creating diary file: $fileName'); // Debug log

      try {
        await DiaryDao.createDiaryFile(fileName);
        final diaryDir = await DiaryDao.getDiaryDir();
        final file = File('$diaryDir/$fileName');

        print('File path: ${file.path}'); // Debug log
        print('File exists: ${await file.exists()}'); // Debug log

        if (await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.createSuccess)));
          }
          await _loadFiles();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.createFailedFileNotCreated)));
          }
        }
      } catch (e) {
        print('Error creating file: $e'); // Debug log
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.createFailedWithError(e.toString()))));
        }
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
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and action bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.myDiary,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _ActionButton(icon: Icons.refresh, tooltip: AppLocalizations.of(context)!.refresh, onPressed: _loadFiles),
              const SizedBox(width: 8),
              _ActionButton(icon: Icons.add, tooltip: AppLocalizations.of(context)!.newDiary, onPressed: _createFile),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        if (!_loading)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor, width: 1),
              ),
              child: _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 64, color: context.secondaryTextColor),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noDiaryYet,
                            style: TextStyle(
                              fontSize: 16,
                              color: context.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.clickToCreateFirstDiary,
                            style: TextStyle(fontSize: 14, color: context.secondaryTextColor),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      thumbVisibility: true,
                      child: ListView.separated(
                        primary: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: _files.length,
                        separatorBuilder: (context, index) => Divider(color: context.borderColor, height: 1),
                        itemBuilder: (ctx, i) {
                          final f = _files[i];
                          return FutureBuilder<DateTime?>(
                            future: getDiaryCreatedTime(f),
                            builder: (context, snapshot) {
                              final dt = snapshot.data;
                              return _DiaryListItem(
                                fileName: f,
                                createdTime: dt,
                                onTap: () {
                                  if (widget.onFileSelected != null) {
                                    widget.onFileSelected!(f);
                                  } else {
                                    Navigator.of(
                                      context,
                                    ).push(MaterialPageRoute(builder: (_) => DiaryContentPage(fileName: f)));
                                  }
                                },
                                onDelete: () => _deleteFile(f),
                              );
                            },
                          );
                        },
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

// Action button component
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.secondaryTextColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(icon, size: 18, color: context.primaryTextColor),
        ),
      ),
    );
  }
}

// Diary list item component
class _DiaryListItem extends StatelessWidget {
  final String fileName;
  final DateTime? createdTime;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DiaryListItem({
    required this.fileName,
    required this.createdTime,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.secondaryTextColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.auto_stories, size: 20, color: context.secondaryTextColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: context.primaryTextColor),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (createdTime != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${AppLocalizations.of(context)!.monthDay(createdTime!.month, createdTime!.day)}  ${createdTime!.hour.toString().padLeft(2, '0')}:${createdTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
