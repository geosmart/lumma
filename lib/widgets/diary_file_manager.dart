import 'dart:io';
import 'package:flutter/material.dart';
import '../services/markdown_service.dart';
import '../services/diary_frontmatter_util.dart';
import '../pages/diary_content_page.dart';

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
        SnackBar(content: Text('加载日记文件失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteFile(String file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除日记文件 "$file" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await MarkdownService.deleteDiaryFile(file);
      await _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除成功')));
      }
    }
  }

  Future<void> _createFile() async {
    final nameCtrl = TextEditingController();
    final fileName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建日记'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: '请输入新日记文件名'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()), child: const Text('创建')),
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
        Row(
          children: [
            const Text('日记列表', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新列表',
              onPressed: _loadFiles,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '新建日记',
              onPressed: _createFile,
            ),
          ],
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        if (!_loading)
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                primary: true, // 关键修复：让 ListView 绑定 PrimaryScrollController，避免移动端报错
                itemCount: _files.length,
                itemBuilder: (ctx, i) {
                  final f = _files[i];
                  return FutureBuilder<DateTime?>(
                    future: getDiaryCreatedTime(f),
                    builder: (context, snapshot) {
                      final dt = snapshot.data;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (dt != null)
                              Text(
                                '${dt.month}月${dt.day}日  ${dt.hour.toString().padLeft(2, '0')}时${dt.minute.toString().padLeft(2, '0')}分',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                          ],
                        ),
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
                        trailing: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 40), // 只保留删除按钮
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: '删除',
                                onPressed: () => _deleteFile(f),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
