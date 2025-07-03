import 'package:flutter/material.dart';
import '../util/markdown_service.dart';
import 'dart:io';
import '../widgets/enhanced_markdown.dart';

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
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          if (!_editMode && !_loading)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '编辑',
              onPressed: () {
                setState(() {
                  _editMode = true;
                });
              },
            ),
        ],
      ),
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
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '编辑日记',
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.fromLTRB(12, 16, 12, 12),
                            isDense: true,
                          ),
                          strutStyle: const StrutStyle(
                            height: 1.0,
                            forceStrutHeight: true,
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
              : _content == null
                  ? const Center(child: Text('无内容'))
                  : _buildChatView(context),
    );
  }

  // 新增：只读chat风格展示
  Widget _buildChatView(BuildContext context) {
    final history = parseDiaryMarkdownToChatHistory(_content!);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: history.length,
      itemBuilder: (ctx, i) {
        final h = history[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23272A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 左侧：时间+标题
                  Expanded(
                    child: Row(
                      children: [
                        if (h['time'] != null)
                          Text(
                            h['time']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                          ),
                        if ((h['title'] ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            h['title']!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[300]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 右侧：标签
                  if (h['category'] != null && h['category']!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal[200]!),
                      ),
                      child: Text(
                        h['category']!,
                        style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (h['q'] != null && h['q']!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: EnhancedMarkdown(data: h['q'] ?? ''),
                ),
              if (h['a'] != null && h['a']!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8, left: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2F33) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: Colors.blueGrey[200]!, width: 3)),
                  ),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 6.5, // 原为13，缩小一倍
                      color: Colors.grey[600],
                    ),
                    child: EnhancedMarkdown(data: h['a'] ?? ''),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 新增：解析markdown为对话轮的函数
  List<Map<String, String>> parseDiaryMarkdownToChatHistory(String content) {
    final lines = content.split('\n');
    List<Map<String, String>> history = [];
    Map<String, String> current = {};
    String? lastSection;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('## ')) {
        if (current.isNotEmpty) history.add(current);
        current = {'title': line.substring(3)};
        lastSection = null;
      } else if (line.startsWith('### 时间')) {
        lastSection = 'time';
      } else if (line.startsWith('### 分类')) {
        lastSection = 'category';
      } else if (line.startsWith('### 日记内容')) {
        lastSection = 'q';
      } else if (line.startsWith('### 内容分析')) {
        lastSection = 'a';
      } else if (line.trim() == '---') {
        if (current.isNotEmpty) history.add(current);
        current = {};
        lastSection = null;
      } else if (lastSection != null && line.trim().isNotEmpty) {
        current[lastSection] = (current[lastSection] ?? '') + (current[lastSection]?.isNotEmpty == true ? '\n' : '') + line.trim();
      }
    }
    if (current.isNotEmpty) history.add(current);
    // 按时间降序排序（最近的在前面）
    history.sort((a, b) {
      final t1 = a['time'] ?? '';
      final t2 = b['time'] ?? '';
      return t2.compareTo(t1);
    });
    return history;
  }
}
