import 'dart:io';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../util/markdown_service.dart';
import '../util/diary_frontmatter_util.dart';
import '../config/theme_service.dart';
import '../diary/diary_content_page.dart';

/// 日记文件管理组件，集成列表、增删改查、编辑、选择等全部逻辑
class DiaryFileManager extends StatefulWidget {
  /// 选中文件后回调（可选）
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
      final files = await MarkdownService.listDiaryFiles();
      // 按 frontmatter 的 created 字段降序排序
      final filesWithCreated = await Future.wait(files.map((f) async {
        final dt = await getDiaryCreatedTime(f);
        return {'file': f, 'created': dt};
      }));
      filesWithCreated.sort((a, b) {
        final adt = a['created'] as DateTime?;
        final bdt = b['created'] as DateTime?;
        if (adt == null && bdt == null) return 0;
        if (adt == null) return 1;
        if (bdt == null) return -1;
        return bdt.compareTo(adt); // 降序
      });
      setState(() {
        _files = filesWithCreated.map((e) => e['file'] as String).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _files = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.loading}${AppLocalizations.of(context)!.noFilesFound}: ${e.toString()}')),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await MarkdownService.deleteDiaryFile(file);
      await _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.delete} ${AppLocalizations.of(context)!.ok}')));
      }
    }
  }

  Future<void> _createFile() async {
    final nameCtrl = TextEditingController();
    final fileName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newDiary),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.enterFileName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: Text(AppLocalizations.of(context)!.create)),
        ],
      ),
    );
    if (fileName != null && fileName.isNotEmpty) {
      try {
        await MarkdownService.createDiaryFile(fileName);
        final diaryDir = await MarkdownService.getDiaryDir();
        final file = File('$diaryDir/$fileName');
        if (await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新建成功')));
          }
          await _loadFiles();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新建失败，文件未创建')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('新建失败: \n${e.toString()}')));
        }
      }
    }
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
        // 标题和操作栏
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.borderColor,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Text(
                '我的日记',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: context.primaryTextColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _ActionButton(
                icon: Icons.refresh,
                tooltip: '刷新',
                onPressed: _loadFiles,
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.add,
                tooltip: '新建日记',
                onPressed: _createFile,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_loading)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        if (!_loading)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
              ),
              child: _files.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 64,
                            color: context.secondaryTextColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '还没有任何日记',
                            style: TextStyle(
                              fontSize: 16,
                              color: context.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击右上角的 + 开始写你的第一篇日记吧',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.secondaryTextColor,
                            ),
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
                        separatorBuilder: (context, index) => Divider(
                          color: context.borderColor,
                          height: 1,
                        ),
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
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DiaryContentPage(fileName: f),
                                      ),
                                    );
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

// 操作按钮组件
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: context.secondaryTextColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(
            icon,
            size: 18,
            color: context.primaryTextColor,
          ),
        ),
      ),
    );
  }
}

// 日记列表项组件
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
                child: Icon(
                  Icons.auto_stories,
                  size: 20,
                  color: context.secondaryTextColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: context.primaryTextColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (createdTime != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${createdTime!.month}月${createdTime!.day}日  ${createdTime!.hour.toString().padLeft(2, '0')}:${createdTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
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
