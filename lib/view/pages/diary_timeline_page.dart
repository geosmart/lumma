import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lumma/dao/diary_dao.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/view/widgets/ai_result_page.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/view/pages/diary_file_list_page.dart';

class DiaryTimelinePage extends StatefulWidget {
  const DiaryTimelinePage({super.key});

  @override
  State<DiaryTimelinePage> createState() => _DiaryTimelinePageState();
}

class _DiaryTimelinePageState extends State<DiaryTimelinePage> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<DiaryEntry> _entries = [];
  String? _diaryFileName;
  bool _diaryCreated = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    await _createDiary();
    await _loadTodayTimeline();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createDiary() async {
    try {
      final fileName = DiaryDao.getDiaryFileName();
      _diaryFileName = fileName;

      final diaryDir = await DiaryDao.getDiaryDir();
      final file = File('$diaryDir/$fileName');

      if (!await file.exists()) {
        final now = DateTime.now();
        final initialContent =
            '# ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 时间线日记\n\n';
        await DiaryDao.saveDiaryMarkdown(initialContent, fileName: fileName);
      }

      setState(() {
        _diaryCreated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建日记失败: $e')));
      }
    }
  }

  Future<void> _loadTodayTimeline() async {
    try {
      final diaryDir = await DiaryDao.getDiaryDir();
      final fileName = DiaryDao.getDiaryFileName();
      final file = File('$diaryDir/$fileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        final entries = DiaryDao.parseDiaryContent(context, content);

        if (mounted && entries.isNotEmpty) {
          setState(() {
            _entries.clear();
            _entries.addAll(entries); // Load in ascending time order (oldest first)
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('加载时间线失败: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSubmit() async {
    if (_ctrl.text.trim().isEmpty) return;
    if (_isSaving) return;

    final userContent = _ctrl.text.trim();

    setState(() {
      _ctrl.clear();
      _isSaving = true;
    });

    try {
      // Save to diary using timeline-specific method
      await DiaryDao.appendTimelineDiaryEntry(
        context: context,
        userContent: userContent,
        shouldCorrect: null, // Use default correction setting
      );

      // Reload entries to reflect the new entry with proper numbering
      await _loadTodayTimeline();

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.cardBackgroundColor,
        elevation: 0.2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.secondaryTextColor),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '返回',
        ),
        title: Text(
          '时间线叙事',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryTextColor),
        ),
      ),
      body: Column(
        children: [
          // Timeline content area
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: _entries.length,
                itemBuilder: (ctx, i) {
                  final entry = _entries[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline indicator
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF4CAF50)
                                    : Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (i < _entries.length - 1)
                              Container(
                                width: 2,
                                height: 40,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.displayTime ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.q ?? '',
                                  style: TextStyle(fontSize: 15, color: context.primaryTextColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Input area
          Material(
            color: context.cardBackgroundColor,
            elevation: 1.0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.smart_toy, color: Colors.deepOrange),
                          tooltip: AppLocalizations.of(context)!.aiSummary,
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AiResultPage(
                                  title: AppLocalizations.of(context)!.aiSummaryResult,
                                  fileName: _diaryFileName,
                                  onBack: () {
                                    Navigator.of(context).pop();
                                  },
                                  getContent: () async {
                                    if (!_diaryCreated || _diaryFileName == null) return null;
                                    final diaryDir = await DiaryDao.getDiaryDir();
                                    final file = File('$diaryDir/$_diaryFileName');
                                    return await file.readAsString();
                                  },
                                ),
                              ),
                            );

                            if (result == true) {
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.menu_book, color: Colors.teal),
                          tooltip: AppLocalizations.of(context)!.viewDiaryList,
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiaryFileListPage()));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _ctrl,
                              style: TextStyle(color: context.primaryTextColor),
                              decoration: InputDecoration(
                                hintText: '记录此刻...',
                                hintStyle: TextStyle(color: context.secondaryTextColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                              minLines: 1,
                              maxLines: 4,
                              onSubmitted: (value) => _onSubmit(),
                              enabled: !_isSaving,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          width: 56,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _isSaving ? null : _onSubmit,
                            child: Center(
                              child: _isSaving
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  : Icon(
                                      Icons.send,
                                      size: 30,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Theme.of(context).primaryColor,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
