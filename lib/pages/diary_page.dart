import 'dart:io';
import 'package:flutter/material.dart';
import 'diary_detail_page.dart';
import '../services/markdown_service.dart';
import 'diary_qa_page.dart';
import 'diary_chat_page.dart';

class DiaryPage extends StatefulWidget {
  final void Function(BuildContext context)? onNewDiary;
  const DiaryPage({super.key, this.onNewDiary});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<FileSystemEntity> _diaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    final dir = await MarkdownService.getDiaryDir();
    final files = Directory(dir).listSync().where((f) => f.path.endsWith('.md')).toList();
    setState(() {
      _diaries = files;
      _loading = false;
    });
  }

  void _showDiary(FileSystemEntity file) async {
    final content = await File(file.path).readAsString();
    // 跳转到详情页，支持markdown预览和所见即所得编辑
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => DiaryDetailPage(
          title: file.path.split('/').last,
          content: content,
          onSave: (newContent) async {
            await File(file.path).writeAsString(newContent);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
              _loadDiaries();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        shadowColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('本地问答日记'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiaryQaPage()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('AI问答日记'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DiaryChatPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: const Divider(height: 1)),
          _loading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final f = _diaries[i];
                      final name = f.path.split('/').last;
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(name, style: Theme.of(context).textTheme.titleMedium),
                          onTap: () => _showDiary(f),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                    childCount: _diaries.length,
                  ),
                ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
