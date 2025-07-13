import 'package:flutter/material.dart';
import 'dart:io';
import '../util/markdown_service.dart';
import 'diary_qa_title_service.dart';
import '../config/config_service.dart';
import '../config/theme_service.dart';
import '../dao/diary_dao.dart';
import '../widgets/ai_result_page.dart';
import '../generated/l10n/app_localizations.dart';
import 'diary_file_list_page.dart';
import 'qa_questions_service.dart';

class DiaryQaPage extends StatefulWidget {
  const DiaryQaPage({super.key});

  @override
  State<DiaryQaPage> createState() => _DiaryQaPageState();
}

class _DiaryQaPageState extends State<DiaryQaPage> {
  List<String> _questions = [];
  final List<String> _answers = [];
  int _current = 0;
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _aiResultController = TextEditingController();

  String? _diaryFileName; // 当前日记文件名
  bool _diaryCreated = false; // 是否已创建日记

  // AI相关状态

  @override
  void initState() {
    super.initState();
    _createDiary();
    _loadQuestions();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    _aiResultController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      // 首先初始化默认问题（如果问题列表为空）
      await QaQuestionsService.init(context);

      final config = await AppConfigService.load();
      final questions = config.qaQuestions;
      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loadingFailed)),
        );
      }
    }
  }

  Future<void> _createDiary() async {
    try {
      final fileName = MarkdownService.getDiaryFileName();
      _diaryFileName = fileName;

      final diaryDir = await MarkdownService.getDiaryDir();
      final file = File('$diaryDir/$fileName');

      if (!await file.exists()) {
        final initialContent = '# 今日问答日记\n\n---\n\n';
        await MarkdownService.saveDiaryMarkdown(initialContent, fileName: fileName);
      }

      setState(() {
        _diaryCreated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.createFailedWithError(e.toString()))),
        );
      }
    }
  }



  // Auto-save Q&A to diary file
  Future<void> _autoSaveToDiary(String question, String answer) async {
    if (!_diaryCreated || _diaryFileName == null) return;

    try {
      final content = DiaryDao.formatDiaryContent(
        context: context,
        title: question,
        content: answer,
        analysis: '',
      );
      await MarkdownService.appendToDailyDiary(content);

      // Print save path (for debug)
      print(AppLocalizations.of(context)!.saveSuccess);
    } catch (e) {
      print(AppLocalizations.of(context)!.saveFailed);
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getDiaryQaTitle(context),
      builder: (context, snapshot) {
        final title = snapshot.data ?? '固定问答式日记';
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
            title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryTextColor)),
          ),
          body: Column(
            children: [
              // 聊天内容区域 - 占用剩余空间
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: (_current + 1).clamp(0, _questions.length),
                    itemBuilder: (ctx, i) {
                      final isAnswered = i < _answers.length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 问题部分 - 带AI头像
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF37474F) // 深色模式下的深蓝灰色
                                    : Colors.blueGrey[50], // 浅色模式下的浅蓝灰色
                                child: Icon(
                                  Icons.smart_toy,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF90A4AE) // 深色模式下的蓝灰色图标
                                      : Colors.blueGrey, // 浅色模式下的蓝灰色图标
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text('Q${i + 1}: ${_questions[i]}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: context.primaryTextColor)),
                                ),
                              ),
                              const SizedBox(width: 32),
                            ],
                          ),
                          // 答案部分 - 带用户头像
                          if (isAnswered)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SizedBox(width: 32),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 2, bottom: 12),
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF2D5A2B) // 深色模式下的深绿色
                                          : Theme.of(context).colorScheme.primary.withAlpha(30),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(_answers[i], style: TextStyle(color: context.primaryTextColor)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF2D5A2B) // 深色模式下的深绿色
                                      : const Color(0xFFE8F5E9), // 浅色模式下的浅绿色
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF4CAF50) // 深色模式下的绿色图标
                                        : Colors.green, // 浅色模式下的绿色图标
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // 参考 chat_page 的底部输入栏和工具栏布局，彻底防止被挤走
              if (_questions.isNotEmpty && _current <= _questions.length)
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
                                        fileName: _diaryFileName, // Pass current diary file name
                                        onBack: () {
                                          Navigator.of(context).pop();
                                        },
                                        getContent: () async {
                                          if (!_diaryCreated || _diaryFileName == null) return null;
                                          final diaryDir = await MarkdownService.getDiaryDir();
                                          final file = File('$diaryDir/$_diaryFileName');
                                          return await file.readAsString();
                                        },
                                      ),
                                    ),
                                  );

                                  // If result is true, refresh the diary content
                                  if (result == true) {
                                    // Trigger a rebuild to refresh the content
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              // 日记列表按钮
                              IconButton(
                                icon: const Icon(Icons.menu_book, color: Colors.teal),
                                tooltip: AppLocalizations.of(context)!.viewDiaryList,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const DiaryFileListPage()),
                                  );
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
                                      hintText: _current < _questions.length
                                        ? AppLocalizations.of(context)!.aiContentPlaceholder
                                        : AppLocalizations.of(context)!.qaNone,
                                      hintStyle: TextStyle(color: context.secondaryTextColor),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    onSubmitted: (value) => _onSubmit(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                width: 56,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: _onSubmit,
                                  child: Center(
                                    child: Icon(
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
      },
    );
  }

  void _onSubmit() async {
    // Check if there are more questions to answer
    if (_current >= _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已完成所有问题')),
      );
      return;
    }

    final answer = _ctrl.text.trim();
    final question = _questions[_current];

    if (answer.isEmpty) {
      // No input, do not advance or save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容后再提交')),
      );
      return;
    }

    setState(() {
      _answers.add(answer);
      _ctrl.clear();
      _current++;
    });

    // 等待保存完成
    await _autoSaveToDiary(question, answer);
    _scrollToBottom();
  }
}
