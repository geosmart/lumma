import 'package:flutter/material.dart';
import 'package:lumma/view/widgets/enhanced_markdown.dart';
import 'package:lumma/service/diary_content_service.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/view/widgets/edit_diary_entry_dialog.dart';
import 'package:lumma/dao/diary_dao.dart';

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

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.loadingFailed}: $e')));
    }
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
                      enableInteractiveSelection: true,
                      enableSuggestions: true,
                      autocorrect: true,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context)!.editDiary,
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        isDense: true,
                      ),
                      strutStyle: const StrutStyle(height: 1.0, forceStrutHeight: true),
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
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saveSuccess)));
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.saveFailed}: $e')));
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: Text(AppLocalizations.of(context)!.save),
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
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

  // Chat-style display for diary entries
  Widget _buildChatView(BuildContext context) {
    final history = DiaryDao.parseDiaryContent(context, _content!);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: history.length,
      itemBuilder: (ctx, i) {
        final entry = history[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF23272A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
            border: Border.all(color: Colors.grey.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (entry.time != null)
                          Text(
                            entry.displayTime ?? entry.time!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                          ),
                        if (entry.title.isNotEmpty) ...[
                          if (entry.time != null) const SizedBox(width: 8),
                          Text(
                            entry.title,
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
                  if (entry.category != null && entry.category!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        entry.category!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (entry.q != null && entry.q!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: EnhancedMarkdown(data: entry.q!),
                ),
              if (entry.a != null && entry.a!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8, left: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2F33) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: Colors.blueGrey[200]!, width: 3)),
                  ),
                  child: EnhancedMarkdown(data: entry.a!),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text(AppLocalizations.of(context)!.edit),
                    onPressed: () async {
                      final result = await showDialog<Map<String, String>>(
                        context: context,
                        builder: (context) => EditDiaryEntryDialog(
                          initialEntry: entry.toMap(),
                          allCategories: const ['工作', '生活', '学习', '健康', '其他'],
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          history[i] = DiaryEntry.fromMap(result);
                          _content = DiaryDao.diaryContentToMarkdown(context, history);
                        });
                        await DiaryContentService.saveDiaryContent(_content!, widget.fileName);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saveSuccess)));
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(AppLocalizations.of(context)!.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.delete),
                          content: Text(AppLocalizations.of(context)!.deleteConfirmMessage),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text(AppLocalizations.of(context)!.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(AppLocalizations.of(context)!.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        setState(() {
                          history.removeAt(i);
                          _content = DiaryDao.diaryContentToMarkdown(context, history);
                        });
                        await DiaryContentService.saveDiaryContent(_content!, widget.fileName);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.deleteSuccess)));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
