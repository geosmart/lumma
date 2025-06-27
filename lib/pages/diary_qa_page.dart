import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/markdown_service.dart';
import '../services/diary_qa_title_service.dart';

class DiaryQaPage extends StatefulWidget {
  const DiaryQaPage({super.key});

  @override
  State<DiaryQaPage> createState() => _DiaryQaPageState();
}

class _DiaryQaPageState extends State<DiaryQaPage> {
  final List<String> _questions = [
    '今天哪些细节引起了你的注意？',
    '今天谁做了什么具体的事？',
    '今天你做成了什么事？',
    '什么时候你感到开心、轻松或觉得有趣？',
    '今天你收到了哪些支持或善意？',
    '今天你遇到了哪些外部挑战？',
    '你在什么时候感受到不适的情绪？',
    '你的身体有没有发出一些信号？',
    '我今天又出现了什么反应模式？',
    '针对今日问题制定明日可行的小步优化？',
  ];
  final List<String> _answers = [];
  int _current = 0;
  bool _summaryLoading = false;
  bool _summaryInterrupted = false;
  String? _summary;
  String _streamingSummary = '';
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _next() async {
    final answer = _ctrl.text.trim().isEmpty ? '无' : _ctrl.text.trim();
    setState(() {
      _answers.add(answer);
      _ctrl.clear();
      _current++;
    });
    _scrollToBottom();
    if (_current == _questions.length) {
      setState(() {
        _summaryLoading = true;
        _streamingSummary = '';
        _summaryInterrupted = false;
      });
      await AiService.summaryWithPromptStream(
        questions: _questions,
        answers: _answers,
        onDelta: (content) {
          if (!_summaryInterrupted) {
            setState(() {
              _streamingSummary = content;
            });
          }
        },
        onDone: (content) {
          if (!_summaryInterrupted) {
            setState(() {
              _summary = content;
              _summaryLoading = false;
              _streamingSummary = '';
            });
          }
        },
        onError: (err) {
          if (!_summaryInterrupted) {
            setState(() {
              _summaryLoading = false;
              _streamingSummary = 'AI接口错误: $err';
            });
          }
        },
      );
    }
  }

  Future<void> _saveDiary() async {
    final content = StringBuffer();
    for (int i = 0; i < _questions.length; i++) {
      content.writeln('* ${_questions[i]}');
      content.writeln('  - ${_answers[i]}');
    }
    content.writeln('\n---\n$_summary');
    try {
      await MarkdownService.saveDiaryMarkdown(content.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日记已保存')));
        Navigator.of(context).pop(true); // 保存后返回并通知刷新
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: \n${e.toString()}')),
        );
      }
    }
  }

  void _interruptSummary() {
    setState(() {
      _summaryInterrupted = true;
      _summaryLoading = false;
    });
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
      future: getDiaryQaTitle(),
      builder: (context, snapshot) {
        final title = snapshot.data ?? 'AI 问答式日记';
        if (_summaryLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('日记总结')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI 总结（流式返回）：', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      alignment: Alignment.topLeft,
                      child: SelectableText(_streamingSummary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('保存日记'),
                      onPressed: _saveDiary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (_summary != null) {
          return Scaffold(
            appBar: AppBar(title: Text('日记总结')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI 总结：', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_summary!),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('保存日记'),
                      onPressed: _saveDiary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (_current == _questions.length && _summary == null && !_summaryLoading) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('所有问题已完成，请选择：', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI总结并保存到日记'),
                    onPressed: _onAiSummaryAndSave,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('直接保存到日记'),
                    onPressed: _onSaveDirect,
                  ),
                ],
              ),
            ),
          );
        }
        // 聊天气泡风格
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _current + 1, // 展示到当前问题
                  itemBuilder: (ctx, i) {
                    final isAnswered = i < _answers.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 问题气泡（左侧）
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
                          // 回答气泡（右侧）
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(top: 2, left: 48, bottom: 12),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
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
              // 聊天输入区
              if (_current < _questions.length)
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          decoration: InputDecoration(
                            hintText: '请输入你的回答...（${_current + 1}/${_questions.length}）',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          ),
                          onSubmitted: (value) => _onSubmit(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _onSubmit,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.send, size: 32, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onSubmit() {
    final answer = _ctrl.text.trim().isEmpty ? '无' : _ctrl.text.trim();
    setState(() {
      _answers.add(answer);
      _ctrl.clear();
      _current++;
    });
    _scrollToBottom();
    if (_current == _questions.length) {
      setState(() {
        _summary = null;
      });
      // 不自动总结，等待用户选择
    }
  }

  void _onAiSummaryAndSave() async {
    setState(() {
      _summaryLoading = true;
      _summaryInterrupted = false;
      _streamingSummary = '';
    });
    await AiService.summaryWithPromptStream(
      questions: _questions,
      answers: _answers,
      onDelta: (content) {
        if (!_summaryInterrupted) {
          setState(() {
            _streamingSummary = content;
          });
        }
      },
      onDone: (content) async {
        if (!_summaryInterrupted) {
          setState(() {
            _summary = content;
            _summaryLoading = false;
            _streamingSummary = '';
          });
          await _saveDiary();
        }
      },
      onError: (err) {
        if (!_summaryInterrupted) {
          setState(() {
            _summaryLoading = false;
            _streamingSummary = 'AI接口错误: $err';
          });
        }
      },
    );
  }

  void _onSaveDirect() async {
    final content = StringBuffer();
    for (int i = 0; i < _questions.length; i++) {
      content.writeln('* ${_questions[i]}');
      content.writeln('  - ${_answers[i]}');
    }
    try {
      await MarkdownService.saveDiaryMarkdown(content.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('日记已保存')));
        Navigator.of(context).pop(true); // 保存后返回并通知刷新
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: \n${e.toString()}')),
        );
      }
    }
  }
}
