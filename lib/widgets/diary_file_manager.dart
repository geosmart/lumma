import 'dart:io';
import 'package:flutter/material.dart';
import '../services/markdown_service.dart';

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
  String? _editingFile;
  final TextEditingController _editCtrl = TextEditingController();
  bool _saving = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载日记文件失败: ${e.toString()}')),
      );
    }
  }

  Future<void> _editFile(String file) async {
    setState(() {
      _editingFile = file;
      _editCtrl.text = '';
      _saving = false;
    });
    final diaryDir = await MarkdownService.getDiaryDir();
    final f = File('$diaryDir/$file');
    if (await f.exists()) {
      _editCtrl.text = await f.readAsString();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _editCtrl,
                maxLines: 12,
                decoration: InputDecoration(
                  labelText: file,
                  border: const OutlineInputBorder(),
                ),
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
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              final diaryDir = await MarkdownService.getDiaryDir();
                              final f = File('$diaryDir/$file');
                              await f.writeAsString(_editCtrl.text);
                              setState(() => _saving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
                                Navigator.of(ctx).pop();
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _editingFile = null;
        _editCtrl.clear();
      });
    });
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
            const Text('日记文件', style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (ctx, i) {
                final f = _files[i];
                return ListTile(
                  title: Text(f),
                  onTap: () {
                    if (widget.onFileSelected != null) {
                      widget.onFileSelected!(f);
                    } else {
                      _editFile(f);
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: '编辑',
                        onPressed: () => _editFile(f),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: '删除',
                        onPressed: () => _deleteFile(f),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
