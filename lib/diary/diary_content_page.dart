import 'package:flutter/material.dart';
import '../util/markdown_service.dart';
import 'dart:io';
import '../widgets/enhanced_markdown.dart';
import '../dao/diary_dao.dart';

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

  // 根据标签类型返回对应的颜色配置
  Map<String, Color> _getCategoryColors(String category) {
    final lowerCategory = category.toLowerCase();

    // 观察类标签 - 蓝色系
    if (lowerCategory.contains('observe') || lowerCategory.contains('观察') ||
        lowerCategory.contains('环境') || lowerCategory.contains('他人')) {
      return {
        'background': Colors.blue[50]!,
        'border': Colors.blue[200]!,
        'text': Colors.blue[700]!,
      };
    }

    // 积极/好事类标签 - 绿色系
    if (lowerCategory.contains('good') || lowerCategory.contains('成就') ||
        lowerCategory.contains('喜悦') || lowerCategory.contains('感恩')) {
      return {
        'background': Colors.green[50]!,
        'border': Colors.green[200]!,
        'text': Colors.green[700]!,
      };
    }

    // 困难/挑战类标签 - 红色系
    if (lowerCategory.contains('difficult') || lowerCategory.contains('挑战') ||
        lowerCategory.contains('情绪') || lowerCategory.contains('身体')) {
      return {
        'background': Colors.red[50]!,
        'border': Colors.red[200]!,
        'text': Colors.red[700]!,
      };
    }

    // 改进/不同类标签 - 紫色系
    if (lowerCategory.contains('different') || lowerCategory.contains('觉察') ||
        lowerCategory.contains('改进')) {
      return {
        'background': Colors.purple[50]!,
        'border': Colors.purple[200]!,
        'text': Colors.purple[700]!,
      };
    }

    // 日总结 - 橙色系（特别处理）
    if (lowerCategory.contains('日总结') || lowerCategory.contains('总结') ||
        lowerCategory == '## 日总结') {
      return {
        'background': Colors.orange[50]!,
        'border': Colors.orange[200]!,
        'text': Colors.orange[700]!,
      };
    }

    // 工作相关 - 靛蓝色系
    if (lowerCategory.contains('工作') || lowerCategory.contains('职场') ||
        lowerCategory.contains('meeting') || lowerCategory.contains('项目')) {
      return {
        'background': Colors.indigo[50]!,
        'border': Colors.indigo[200]!,
        'text': Colors.indigo[700]!,
      };
    }

    // 生活相关 - 棕色系
    if (lowerCategory.contains('生活') || lowerCategory.contains('日常') ||
        lowerCategory.contains('家庭') || lowerCategory.contains('休闲')) {
      return {
        'background': Colors.brown[50]!,
        'border': Colors.brown[200]!,
        'text': Colors.brown[700]!,
      };
    }

    // 学习相关 - 深紫色系
    if (lowerCategory.contains('学习') || lowerCategory.contains('读书') ||
        lowerCategory.contains('知识') || lowerCategory.contains('技能')) {
      return {
        'background': Colors.deepPurple[50]!,
        'border': Colors.deepPurple[200]!,
        'text': Colors.deepPurple[700]!,
      };
    }

    // 健康相关 - 粉红色系
    if (lowerCategory.contains('健康') || lowerCategory.contains('运动') ||
        lowerCategory.contains('饮食') || lowerCategory.contains('锻炼')) {
      return {
        'background': Colors.pink[50]!,
        'border': Colors.pink[200]!,
        'text': Colors.pink[700]!,
      };
    }

    // 其他标签 - 默认青色系
    return {
      'background': Colors.teal[50]!,
      'border': Colors.teal[200]!,
      'text': Colors.teal[700]!,
    };
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

  // 处理内容中的标签，特别是日总结中的标签
  Widget _buildContentWithTags(String content) {
    // 使用正则表达式分割内容和标签
    final tagRegex = RegExp(r'(#[^\s#]+)');

    // 检查是否包含标签
    if (!tagRegex.hasMatch(content)) {
      // 如果没有标签，直接使用Markdown渲染
      return EnhancedMarkdown(data: content);
    }

    final parts = <Widget>[];

    // 按行处理内容
    final lines = content.split('\n');
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      // 如果这行包含标签，则进行特殊处理
      if (tagRegex.hasMatch(line)) {
        final lineWidgets = <Widget>[];
        final matches = tagRegex.allMatches(line);
        int lastEnd = 0;

        for (final match in matches) {
          // 添加标签前的文本
          if (match.start > lastEnd) {
            final beforeText = line.substring(lastEnd, match.start);
            if (beforeText.isNotEmpty) {
              lineWidgets.add(Text(
                beforeText,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[700],
                  fontSize: 14,
                ),
              ));
            }
          }

          // 添加标签Widget
          final tag = match.group(1)!.substring(1); // 去除#号
          lineWidgets.add(_buildTagWidget(tag));

          lastEnd = match.end;
        }

        // 添加标签后的文本
        if (lastEnd < line.length) {
          final afterText = line.substring(lastEnd);
          if (afterText.isNotEmpty) {
            lineWidgets.add(Text(
              afterText,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[300]
                  : Colors.grey[700],
                fontSize: 14,
              ),
            ));
          }
        }

        // 将这行的所有Widget包装在一个Wrap中
        parts.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: lineWidgets,
          ),
        ));
      } else {
        // 不包含标签的行，直接使用Markdown渲染
        if (line.isNotEmpty) {
          parts.add(EnhancedMarkdown(data: line));
        } else {
          parts.add(const SizedBox(height: 8));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  // 处理日总结内容的特殊渲染
  Widget _buildSummaryContent(String content) {
    // 按4个大类分组
    final Map<String, List<String>> groupedContent = {
      'observe': [],
      'good': [],
      'difficult': [],
      'different': [],
    };

    // 解析内容并分组
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;

      if (trimmedLine.contains('#observe')) {
        groupedContent['observe']!.add(trimmedLine);
      } else if (trimmedLine.contains('#good')) {
        groupedContent['good']!.add(trimmedLine);
      } else if (trimmedLine.contains('#difficult')) {
        groupedContent['difficult']!.add(trimmedLine);
      } else if (trimmedLine.contains('#different')) {
        groupedContent['different']!.add(trimmedLine);
      }
    }

    final List<Widget> summaryWidgets = [];

    // 为每个分组创建卡片
    final groupInfo = {
      'observe': {'title': '观察发现', 'icon': Icons.visibility, 'color': Colors.blue},
      'good': {'title': '积极收获', 'icon': Icons.favorite, 'color': Colors.green},
      'difficult': {'title': '困难挑战', 'icon': Icons.warning, 'color': Colors.red},
      'different': {'title': '反思改进', 'icon': Icons.psychology, 'color': Colors.purple},
    };

    for (final group in groupInfo.keys) {
      final items = groupedContent[group]!;
      if (items.isEmpty) continue;

      final info = groupInfo[group]!;
      final color = info['color'] as Color;

      summaryWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 分组标题
              Row(
                children: [
                  Icon(info['icon'] as IconData, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    info['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 分组内容
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSummaryItem(item, color),
              )),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaryWidgets,
    );
  }

  // 构建总结条目
  Widget _buildSummaryItem(String content, Color themeColor) {
    final tagRegex = RegExp(r'(#[^\s#]+)');

    // 去掉所有标签，只显示纯文本内容
    final cleanContent = content.replaceAll(tagRegex, '').trim();

    // 去掉开头的 * 或 - 标记
    final finalContent = cleanContent.replaceFirst(RegExp(r'^[\*\-]\s*'), '');

    return Text(
      finalContent,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[300]
          : Colors.grey[700],
      ),
    );
  }

  // 创建标签Widget
  Widget _buildTagWidget(String tag) {
    final colors = _getCategoryColors(tag);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors['border']!),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 11,
          color: colors['text'],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // 判断是否为日总结内容
  bool _isSummaryContent(String content) {
    // 如果内容包含日总结相关的标签组合，则认为是日总结内容
    final hasObserve = content.contains('#observe');
    final hasGood = content.contains('#good');
    final hasDifficult = content.contains('#difficult');
    final hasDifferent = content.contains('#different');

    // 如果包含至少2个主要分类标签，则认为是日总结内容
    final count = [hasObserve, hasGood, hasDifficult, hasDifferent].where((x) => x).length;
    return count >= 2;
  }

  // 判断是否应该显示时间和标题（日总结时不显示）
  bool _shouldShowTimeAndTitle(Map<String, String> historyItem) {
    final q = historyItem['q'] ?? '';
    final a = historyItem['a'] ?? '';
    return !_isSummaryContent(q) && !_isSummaryContent(a);
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
    final history = DiaryDao.parseDiaryMarkdownToChatHistory(_content!);
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
                  // 左侧：时间+标题（日总结时不显示时间和标题）
                  Expanded(
                    child: Row(
                      children: [
                        if (h['time'] != null && _shouldShowTimeAndTitle(h))
                          Text(
                            h['time']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                          ),
                        if ((h['title'] ?? '').isNotEmpty && _shouldShowTimeAndTitle(h)) ...[
                          if (h['time'] != null)
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
                  // 右侧：标签（日总结时不显示标签，避免重复）
                  if (h['category'] != null && h['category']!.isNotEmpty &&
                      _shouldShowTimeAndTitle(h))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColors(h['category']!)['background'],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _getCategoryColors(h['category']!)['border']!),
                      ),
                      child: Text(
                        h['category']!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColors(h['category']!)['text'],
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (h['q'] != null && h['q']!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: _isSummaryContent(h['q']!)
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.1),
                              Colors.orange.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.orange[600], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '日总结',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                                const Spacer(),
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
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryContent(h['q']!),
                          ],
                        ),
                      )
                    : _buildContentWithTags(h['q']!),
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
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    child: _isSummaryContent(h['a']!)
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.1),
                                Colors.orange.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.orange[600], size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '日总结',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                  const Spacer(),
                                  if (h['time'] != null)
                                    Text(
                                      h['time']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.grey[400]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildSummaryContent(h['a']!),
                            ],
                          ),
                        )
                      : _buildContentWithTags(h['a']!),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
