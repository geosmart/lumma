import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/markdown_service.dart';
import '../widgets/enhanced_markdown.dart';
import '../services/ai_service.dart';
import '../services/chat_history_service.dart';
import 'diary_file_list_page.dart';
import '../services/diary_qa_title_service.dart';
import '../services/prompt_service.dart';

class DiaryChatPage extends StatefulWidget {
  const DiaryChatPage({super.key});

  @override
  State<DiaryChatPage> createState() => _DiaryChatPageState();
}

class _DiaryChatPageState extends State<DiaryChatPage> {
  List<Map<String, String>> _history = [];
  String? _summary;
  final TextEditingController _ctrl = TextEditingController();
  bool _asking = false;
  bool _askInterrupted = false;
  String _askStreaming = '';
  final ScrollController _scrollController = ScrollController();
  String? _lastRequestJson;

  @override
  void initState() {
    super.initState();
    _ctrl.text = '现在开始我们的对话';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_history.isEmpty) {
        _sendAnswer();
      }
    });
  }

  void _interruptAsk() {
    setState(() {
      _askInterrupted = true;
      _asking = false;
    });
  }

  void _askNext() async {
    setState(() {
      _asking = true;
      _askInterrupted = false;
      _askStreaming = '';
    });
    final userInput = _history.isNotEmpty ? _history.last['q'] ?? '' : _ctrl.text.trim();
    final historyWindow = ChatHistoryService.getRecent(_history);

    final systemPrompt = await PromptService.getActivePromptContent('qa');
    final messages = AiService.buildMessages(
      systemPrompt: systemPrompt,
      history: historyWindow,
      userInput: userInput,
    );

    final raw = await AiService.buildChatRequestRaw(
      messages: messages,
      stream: true,
    );
    final prettyJson = const JsonEncoder.withIndent('  ').convert(raw);
    setState(() {
      _lastRequestJson = '```bash\n$prettyJson\n```';
    });
    await AiService.askStream(
      messages: messages,
      onDelta: (content) {
        if (!_askInterrupted) {
          setState(() {
            if (_history.isNotEmpty) {
              _history = ChatHistoryService.updateAnswer(_history, _history.length - 1, content);
            }
            _askStreaming = content;
          });
          _scrollToBottom();
        }
      },
      onDone: (content) async {
        if (!_askInterrupted) {
          setState(() {
            _asking = false;
            _askStreaming = '';
          });

          final systemPrompt = await PromptService.getActivePromptContent('qa');
          final messages = AiService.buildMessages(
            systemPrompt: systemPrompt,
            history: ChatHistoryService.getRecent(_history),
            userInput: '',
          );

          final raw = await AiService.buildChatRequestRaw(
            messages: messages,
            stream: true,
          );
          final prettyJson = const JsonEncoder.withIndent('  ').convert(raw);
          setState(() {
            _lastRequestJson = '```bash\n$prettyJson\n```';
          });
          _scrollToBottom();
        }
      },
      onError: (err) {
        if (!_askInterrupted) {
          setState(() {
            _asking = false;
            _askStreaming = 'AI接口错误: $err';
          });
        }
      },
    );
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

  void _sendAnswer() {
    final userInput = _ctrl.text.trim();
    if (userInput.isEmpty) return;
    setState(() {
      _history = ChatHistoryService.addHistory(_history, question: userInput, answer: '');
      _ctrl.clear();
    });
    _askNext();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getDiaryQaTitle(),
      builder: (context, snapshot) {
        final title = snapshot.data ?? 'AI 问答式日记';
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FB),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // 顶部工具栏区（只保留返回和标题）
                    Container(
                      height: 52,
                      color: Colors.white.withOpacity(0.85),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          // 返回按钮
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
                    // 沉浸式全屏聊天主界面，无AppBar
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _history.length + (_asking ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (_summary != null && i == 0) {
                            return SizedBox.shrink(); // 全屏聊天时不显示AI总结/编辑区
                          }
                          if (i < _history.length) {
                            final h = _history[i];
                            return Column(
                              children: [
                                if (h['q'] != null && h['q']!.isNotEmpty)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const SizedBox(width: 32),
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 4),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.green[100]!),
                                          ),
                                          child: EnhancedMarkdown(data: h['q'] ?? ''),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const CircleAvatar(
                                        backgroundColor: Color(0xFFE8F5E9),
                                        child: Icon(Icons.person, color: Colors.green),
                                      ),
                                    ],
                                  ),
                                if (h['a'] != null && h['a']!.isNotEmpty)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blueGrey[50],
                                        child: const Icon(Icons.smart_toy, color: Colors.blueGrey),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.blue[100]!),
                                          ),
                                          child: EnhancedMarkdown(data: h['a'] ?? ''),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                    ],
                                  ),
                              ],
                            );
                          } else if (_asking && i == _history.length) {
                            // AI 正在思考/流式输出
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blueGrey[50],
                                  child: const Icon(Icons.smart_toy, color: Colors.blueGrey),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: EnhancedMarkdown(data: _askStreaming.isEmpty ? 'AI 正在思考...' : _askStreaming),
                                  ),
                                ),
                                const SizedBox(width: 32),
                              ],
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    // 按钮区：输入框上方，只显示调试、保存、日记列表按钮
                    Container(
                      color: Colors.white.withOpacity(0.95),
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: [
                          // 调试按钮
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
                              icon: const Icon(Icons.bug_report, color: Colors.deepOrange),
                              tooltip: '调试/查看请求JSON',
                              onPressed: () {
                                if (_lastRequestJson != null) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('请求 JSON'),
                                      content: SingleChildScrollView(
                                        child: SelectableText(_lastRequestJson!),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text('关闭'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 保存按钮
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
                              tooltip: '保存当前对话为日记',
                              onPressed: () async {
                                final content = _history.map((h) => 'Q: ${h['q'] ?? ''}\nA: ${h['a'] ?? ''}').join('\n\n');
                                try {
                                  // 覆盖当天的日记文件
                                  await MarkdownService.overwriteDailyDiary(content);
                                  final now = DateTime.now();
                                  final fileName = 'diary_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.md';
                                  final diaryDir = await MarkdownService.getDiaryDir();
                                  final filePath = '$diaryDir/$fileName';
                                  // 打印保存路径
                                  // ignore: avoid_print
                                  print('日记已保存到: $filePath');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('日记已保存到: $filePath')));
                                    // 跳转到日记列表页面
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const DiaryFileListPage()),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('保存失败: \n${e.toString()}')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          // 日记列表按钮
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
                              icon: const Icon(Icons.menu_book, color: Colors.teal),
                              tooltip: '查看日记列表',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const DiaryFileListPage()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 底部输入栏，贴边圆角悬浮
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
                                decoration: const InputDecoration(
                                  hintText: '记下现在的想法...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                                minLines: 1,
                                maxLines: 4,
                                onSubmitted: (_) => _sendAnswer(),
                                enabled: _summary == null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 44,
                            width: 56,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: (!_asking && _summary == null) ? _sendAnswer : null,
                              child: Center(
                                child: Icon(
                                  Icons.send,
                                  size: 30, // 稍大一点
                                  color: (!_asking && _summary == null)
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 悬浮停止按钮，往上移避免遮挡工具栏
                if (_asking)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 140, // 往上移
                    child: Center(
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: FloatingActionButton(
                          heroTag: 'stop-btn',
                          mini: true,
                          backgroundColor: Colors.red[100],
                          elevation: 1,
                          onPressed: _interruptAsk,
                          shape: const CircleBorder(),
                          child: const Icon(Icons.stop, color: Colors.red, size: 22),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
