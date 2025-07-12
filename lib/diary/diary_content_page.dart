import 'package:flutter/material.dart';
import '../widgets/enhanced_markdown.dart';
import '../widgets/ai_result_page.dart';
import 'diary_content_service.dart';
import '../generated/l10n/app_localizations.dart';

/// Single diary detail page, full-screen, read-only Markdown rendering with edit hints
class DiaryContentPage extends StatefulWidget {
  final String fileName;
  const DiaryContentPage({super.key, required this.fileName});

  @override
  State<DiaryContentPage> createState() => _DiaryContentPageState();
}

class _DiaryContentPageState extends State<DiaryContentPage> {
  String? _content;
  bool _loading = true;
  bool _editMode = false;
  final TextEditingController _controller = TextEditingController();

  // AI summary related state
  final TextEditingController _aiResultController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _controller.dispose();
    _aiResultController.dispose();
    super.dispose();
  }

  // Return corresponding color configuration based on tag type
  Map<String, Color> _getCategoryColors(String category) {
    return DiaryContentService.getCategoryColors(category);
  }

  Future<void> _loadContent() async {
    setState(() => _loading = true);

    try {
      final result = await DiaryContentService.loadDiaryContent(widget.fileName);

      setState(() {
        _content = result['content'];
        _controller.text = result['fullContent'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.loadingFailed}: $e')),
      );
    }
  }

  // Handle tags in content, especially tags in daily summary
  Widget _buildContentWithTags(String content) {
    // Check if content contains tags
    if (!DiaryContentService.hasTagsInContent(content)) {
      // If no tags, render directly with Markdown
      return EnhancedMarkdown(data: content);
    }

    final parts = <Widget>[];

    // Process content line by line
    final lines = content.split('\n');
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      // If this line contains tags, handle specially
      if (DiaryContentService.hasTagsInContent(line)) {
        final lineWidgets = <Widget>[];
        final matches = DiaryContentService.getTagMatches(line);
        int lastEnd = 0;

        for (final match in matches) {
          // Add text before tag
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

          // Add tag widget
          final tag = match.group(1)!.substring(1); // 去除#号
          lineWidgets.add(_buildTagWidget(tag));

          lastEnd = match.end;
        }

        // Add text after tag
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

        // Wrap all widgets in this line in a Wrap
        parts.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: lineWidgets,
          ),
        ));
      } else {
        // If line does not contain tags, render with Markdown
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

  // Special rendering for daily summary content
  Widget _buildSummaryContent(String content) {
    final groupedContent = DiaryContentService.parseSummaryContent(content);
    final groupInfo = DiaryContentService.getSummaryGroupInfo(context);
    final List<Widget> summaryWidgets = [];

    // Create card for each group
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
              // Group title
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
              // Group content
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

  // Build summary item
  Widget _buildSummaryItem(String content, Color themeColor) {
    final finalContent = DiaryContentService.cleanSummaryItemContent(content);

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

  // Create tag widget
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

  // Determine if it is summary content
  bool _isSummaryContent(String content) {
    return DiaryContentService.isSummaryContent(content);
  }

  // Determine if time and title should be shown (not shown for summary)
  bool _shouldShowTimeAndTitle(Map<String, String> historyItem) {
    return DiaryContentService.shouldShowTimeAndTitle(historyItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          if (!_editMode && !_loading)
            IconButton(
              icon: const Icon(Icons.smart_toy, color: Colors.deepOrange),
              tooltip: AppLocalizations.of(context)!.aiSummary,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AiResultPage(
                      title: AppLocalizations.of(context)!.aiSummaryResult,
                      onBack: () {
                        Navigator.of(context).pop();
                      },
                      getContent: () async {
                        return _content;
                      },
                    ),
                  ),
                );

                // If result is true, refresh the diary content
                if (result == true) {
                  await _loadContent();
                }
              },
            ),
          if (!_editMode && !_loading)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: AppLocalizations.of(context)!.edit,
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
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: AppLocalizations.of(context)!.editDiary,
                            alignLabelWithHint: true,
                            contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
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
                            try {
                              await DiaryContentService.saveDiaryContent(_controller.text, widget.fileName);
                              setState(() {
                                _content = _controller.text;
                                _editMode = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saveSuccess)));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.saveFailed}: $e')));
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: Text(AppLocalizations.of(context)!.save),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _content == null
                  ? Center(child: Text(AppLocalizations.of(context)!.noContent))
                  : _buildChatView(context),
    );
  }

  // 新增：只读chat风格展示
  Widget _buildChatView(BuildContext context) {
    final history = DiaryContentService.getChatHistoryWithSummaryFirst(context, _content!);
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
                                  AppLocalizations.of(context)!.dailySummary,
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
                                    AppLocalizations.of(context)!.dailySummary,
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
