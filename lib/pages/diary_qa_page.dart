import 'package:flutter/material.dart';
import 'dart:io';
import '../services/markdown_service.dart';
import '../services/diary_qa_title_service.dart';
import '../services/ai_service.dart';
import '../services/config_service.dart';
import '../services/prompt_service.dart';

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
  bool _isLoadingQuestions = true;

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
    setState(() {
      _isLoadingQuestions = true;
    });
    try {
      final questions = await ConfigService.loadQaQuestions();
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoadingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingQuestions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载问题列表失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createDiary() async {
    try {
      final now = DateTime.now();
      final fileName = 'diary_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.md';
      _diaryFileName = fileName;

      final diaryDir = await MarkdownService.getDiaryDir();
      final file = File('$diaryDir/$fileName');

      if (!await file.exists()) {
        final initialContent = '# 今日问答日记\n\n创建时间: ${now.toString().split('.')[0]}\n\n---\n\n';
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
        onDelta: (buffer) {
          if (mounted) {
            _aiResultController.text = buffer;
          }
        },
        onDone: (finalResult) {
          if (mounted) {
            setState(() {
              _aiResult = finalResult;
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
          backgroundColor: const Color(0xFFF7F9FB),
          body: SafeArea(
            child: Column(
              children: [
                // 顶部工具栏区（只保留返回和标题）
                Container(
                  height: 52,
                  color: Colors.white.withOpacity(0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black54),
                          onPressed: () => Navigator.of(context).maybePop(),
                          tooltip: '返回',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                    ],
                  ),
                ),
                // 主内容区
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: (_current + 1).clamp(0, _questions.length),
                    itemBuilder: (ctx, i) {
                      final isAnswered = i < _answers.length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 4, right: 48),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('Q${i + 1}: ${_questions[i]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          if (isAnswered)
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(top: 2, left: 48, bottom: 12),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withAlpha(30),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(_answers[i]),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                // 按钮区：始终显示在输入框上方，左对齐
                Container(
                  color: Colors.white.withOpacity(0.95),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: _isProcessing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.smart_toy, color: Colors.deepOrange),
                          tooltip: 'AI 总结',
                          onPressed: _isProcessing ? null : _startSummaryStream,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.save, color: Colors.blue),
                          tooltip: '完成日记',
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                      // Spacer() 让按钮靠左
                      const Spacer(),
                    ],
                  ),
                ),
                // 底部输入栏，风格与chat_page一致
                if (_current < _questions.length)
                  Container(
                    color: Colors.white.withOpacity(0.95),
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
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
                              decoration: InputDecoration(
                                hintText: '请输入你的回答...（${_current + 1}/${_questions.length}）',
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
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiResultPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 总结结果'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('AI 正在生成中...'),
                  ],
                ),
              ),
            Expanded(
              child: TextField(
                controller: _aiResultController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'AI 生成的内容将显示在这里...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSubmit() async {
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
