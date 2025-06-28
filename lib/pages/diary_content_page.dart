import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/markdown_service.dart';
import 'dart:io';

/// 单篇日记详情页，全屏、只读Markdown渲染，带编辑提示
class DiaryContentPage extends StatefulWidget {
  final String fileName;
  const DiaryContentPage({super.key, required this.fileName});

  @override
  State<DiaryContentPage> createState() => _DiaryContentPageState();
}

class _DiaryContentPageState extends State<DiaryContentPage> {
  String? _content;
  Map<String, String>? _frontmatter;
  String? _filePath;
  bool _loading = true;
  bool _editMode = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _loading = true);
    final diaryDir = await MarkdownService.getDiaryDir();
    final file = File('$diaryDir/${widget.fileName}');
    final content = await MarkdownService.readDiaryMarkdown(file);
    // 解析 frontmatter
    Map<String, String>? frontmatter;
    String body = content;
    if (content.startsWith('---')) {
      final lines = content.split('\n');
      final endIdx = lines.indexWhere((l) => l.trim() == '---', 1);
      if (endIdx > 0) {
        frontmatter = {};
        for (var i = 1; i < endIdx; i++) {
          final line = lines[i];
          final idx = line.indexOf(':');
          if (idx > 0) {
            final key = line.substring(0, idx).trim();
            final value = line.substring(idx + 1).trim();
            frontmatter[key] = value;
          }
        }
        // 去除 frontmatter 部分
        body = lines.sublist(endIdx + 1).join('\n');
      }
    }
    setState(() {
      _content = body;
      _controller.text = content;
      _frontmatter = frontmatter;
      _filePath = file.path;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _editMode
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '编辑日记',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await MarkdownService.saveDiaryMarkdown(_controller.text, fileName: widget.fileName);
                            setState(() {
                              _content = _controller.text;
                              _editMode = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('保存'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_frontmatter != null && _frontmatter!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_filePath != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 72,
                                          child: Text('path:', style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                        ),
                                        Expanded(child: Text(_filePath!, style: TextStyle(fontSize: 13, color: Colors.grey))),
                                      ],
                                    ),
                                  ),
                                ..._frontmatter!.entries.map((e) {
                                  if (e.key == 'reasoning_context' || e.key == 'reasoning') {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        title: Text(
                                          e.key == 'reasoning_context' ? '推理过程' : 'Reasoning',
                                          style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                        ),
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                            child: Text(
                                              e.value,
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 72,
                                            child: Text('${e.key}:', style: TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                                          ),
                                          Expanded(child: Text(e.value, style: TextStyle(fontSize: 13, color: Colors.grey))),
                                        ],
                                      ),
                                    );
                                  }
                                }),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Markdown(
                              data: _content ?? '',
                              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 32,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => setState(() => _editMode = true),
                          child: Material(
                            color: Colors.grey.shade200.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(20),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.edit, color: Colors.black54, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
