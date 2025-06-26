import 'package:flutter/material.dart';
import '../services/markdown_service.dart';

/// 日记文件列表组件，负责日记文件的增删查改
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载日记文件失败: ${e.toString()}')),
      );
    }
  }

  void _onTap(String file) {
    widget.onFileSelected?.call(file);
  }

  void _onDelete(String file) async {
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
      try {
        await MarkdownService.deleteDiaryFile(file);
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除成功')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${e.toString()}')),
        );
      }
    }
  }

  void _onCreate() async {
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
        await _loadFiles();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新建成功')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('新建失败: ${e.toString()}')),
        );
      }
    }
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
              icon: const Icon(Icons.add),
              tooltip: '新建日记',
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

// 此文件已被 DiaryFileManager 替代，保留空壳防止引用报错，可安全删除。
