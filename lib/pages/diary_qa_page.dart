import 'package:flutter/material.dart';
import 'dart:io';
import '../services/markdown_service.dart';
import '../services/diary_qa_title_service.dart';
import '../services/ai_service.dart';
import '../services/config_service.dart';
import '../services/prompt_service.dart';
import '../services/theme_service.dart';

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
  bool _isProcessing = false;
  String? _aiResult; // 非null时表示进入AI结果页

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
      final questions = await ConfigService.loadQaQuestions();
      if (mounted) {
        setState(() {
          _questions = questions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载问题列表失败: ${e.toString()}')),
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
        final now = DateTime.now();
        final initialContent = '# 今日问答日记\n\n---\n\n';
        await MarkdownService.saveDiaryMarkdown(initialContent, fileName: fileName);
      }

      setState(() {
        _diaryCreated = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建日记失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _appendToDialog() async {
    if (!_diaryCreated || _diaryFileName == null) return;

    try {
      final diaryDir = await MarkdownService.getDiaryDir();
      final file = File('$diaryDir/$_diaryFileName');

      if (await file.exists()) {
        final currentContent = await file.readAsString();
        final newEntry = '\n**Q${_answers.length}: ${_questions[_answers.length - 1]}**\n\n${_answers.last}\n\n---\n';
        await file.writeAsString(currentContent + newEntry);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('追加内容失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _startSummaryStream() async {
    if (!_diaryCreated || _diaryFileName == null) return;

    // 立即进入AI结果页并显示加载状态
    setState(() {
      _aiResult = ''; // 触发构建AI结果页
      _isProcessing = true;
      _aiResultController.text = '';
    });

    try {
      final diaryDir = await MarkdownService.getDiaryDir();
      final file = File('$diaryDir/$_diaryFileName');
      final content = await file.readAsString();

      final systemPrompt = await PromptService.getActivePromptContent('summary');
      final messages = AiService.buildMessages(
        systemPrompt: systemPrompt,
        history: [],
        userInput: content,
      );

      await AiService.askStream(
        messages: messages,
        onDelta: (data) {
          if (mounted) {
            _aiResultController.text = data['content'] ?? '';
          }
        },
        onDone: (finalResult) {
          if (mounted) {
            setState(() {
              _aiResult = finalResult['content'] ?? '';
              _isProcessing = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('AI 总结失败: ${error.toString()}')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI 总结失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleAiResultAction(String action) async {
    if (_aiResult == null || _diaryFileName == null) return;
    final editedResult = _aiResultController.text;

    try {
      switch (action) {
        case 'replace':
          await MarkdownService.saveDiaryMarkdown(editedResult, fileName: _diaryFileName);
          break;
        case 'append':
          final diaryDir = await MarkdownService.getDiaryDir();
          final file = File('$diaryDir/$_diaryFileName');
          if (await file.exists()) {
            final currentContent = await file.readAsString();
            await file.writeAsString('$currentContent\n\n---\n\n$editedResult');
          }
          break;
        case 'new':
          final now = DateTime.now();
          final newFileName =
              '${now.toIso8601String().split('.')[0].replaceAll(':', '-')}.md';
          await MarkdownService.saveDiaryMarkdown(editedResult,
              fileName: newFileName);
          break;
      }

      setState(() {
        _aiResult = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作完成: $action')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${e.toString()}')),
        );
      }
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
    if (_aiResult != null) {
      return _buildAiResultPage();
    }
    return FutureBuilder<String>(
      future: getDiaryQaTitle(),
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
                                icon: _isProcessing
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.smart_toy, color: Colors.deepOrange),
                                tooltip: 'AI 总结',
                                onPressed: _isProcessing ? null : _startSummaryStream,
                              ),
                              IconButton(
                                icon: const Icon(Icons.save, color: Colors.blue),
                                tooltip: '完成日记',
                                onPressed: () => Navigator.of(context).pop(true),
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
                                        ? '请输入你的回答...（${_current + 1}/${_questions.length}）'
                                        : '已完成所有问题',
                                      hintStyle: TextStyle(color: context.secondaryTextColor),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    ),
                                    onSubmitted: (value) => _onSubmit(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: _onSubmit,
                                child: Container(
                                  height: 44,
                                  width: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(
                                    Icons.send,
                                    size: 28,
                                    color: Theme.of(context).primaryColor,
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

  Widget _buildAiResultPage() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.cardBackgroundColor,
        title: Text('AI 总结结果', style: TextStyle(color: context.primaryTextColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primaryTextColor),
          onPressed: () {
            setState(() {
              _aiResult = null;
            });
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 操作按钮区，放在输入框上方
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('替换'),
                  onPressed: _isProcessing ? null : () => _handleAiResultAction('replace'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('追加'),
                  onPressed: _isProcessing ? null : () => _handleAiResultAction('append'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.note_add),
                  label: const Text('新增'),
                  onPressed: _isProcessing ? null : () => _handleAiResultAction('new'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 8),
                    Text('AI 正在生成中...', style: TextStyle(color: context.secondaryTextColor)),
                  ],
                ),
              ),
            Expanded(
              child: TextField(
                controller: _aiResultController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: context.primaryTextColor),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  hintText: 'AI 生成的内容将显示在这里...',
                  hintStyle: TextStyle(color: context.secondaryTextColor),
                  fillColor: context.cardBackgroundColor,
                  filled: true,
                  contentPadding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  isDense: true,
                  alignLabelWithHint: true,
                ),
                strutStyle: const StrutStyle(
                  height: 1.0,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() async {
    // 检查是否还有问题可回答
    if (_current >= _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已完成所有问题')),
      );
      return;
    }

    final answer = _ctrl.text.trim().isEmpty ? '无' : _ctrl.text.trim();
    setState(() {
      _answers.add(answer);
      _ctrl.clear();
      _current++;
    });

    await _appendToDialog();

    _scrollToBottom();
  }
}
