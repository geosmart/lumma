import 'dart:convert';
import 'package:flutter/material.dart';
import '../util/ai_service.dart';
import '../util/curl_helper.dart';
import '../util/markdown_service.dart';
import '../util/frontmatter_service.dart';
import '../diary/chat_history_service.dart';
import '../diary/diary_qa_title_service.dart';
import '../config/prompt_service.dart';
import '../config/config_service.dart';
import '../config/theme_service.dart';
import '../diary/diary_file_list_page.dart';
import '../widgets/enhanced_markdown.dart';
import '../model/app_config.dart';
import '../model/enums.dart';

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
  String _askStreamingReasoning = '';
  final ScrollController _scrollController = ScrollController();
  String? _lastRequestJson;
  String _currentModelName = ''; // 当前使用的模型名称

  @override
  void initState() {
    super.initState();
    _ctrl.text = '现在开始我们的对话';
    _loadCurrentModelName(); // 加载当前模型名称
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_history.isEmpty) {
        _sendAnswer();
      }
    });
  }

  // 加载当前模型名称
  void _loadCurrentModelName() async {
    try {
      final config = await AppConfigService.load();
      setState(() {
        _currentModelName = config.model.isNotEmpty ? config.model.first.model : '未知模型';
      });
    } catch (e) {
      setState(() {
        _currentModelName = '未知模型';
      });
    }
  }

  // 显示模型名称的tooltip
  void _showModelTooltip(BuildContext context, Offset position) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx - 100,
        top: position.dy - 60,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _currentModelName.isEmpty ? '加载中...' : _currentModelName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 2秒后自动隐藏
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry?.remove();
    });
  }

  void _interruptAsk() {
    setState(() {
      _askInterrupted = true;
      _asking = false;
      _askStreamingReasoning = '';
    });
  }

  void _askNext() async {
    setState(() {
      _asking = true;
      _askInterrupted = false;
      _askStreaming = '';
      _askStreamingReasoning = '';
    });
    final userInput = _history.isNotEmpty ? _history.last['q'] ?? '' : _ctrl.text.trim();
    final historyWindow = ChatHistoryService.getRecent(_history);

    final systemPrompt = await PromptService.getActivePromptContent(PromptCategory.qa);
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
      onDelta: (data) {
        if (!_askInterrupted) {
          setState(() {
            if (_history.isNotEmpty) {
              _history = ChatHistoryService.updateAnswer(_history, _history.length - 1, data['content'] ?? '');
            }
            _askStreaming = data['content'] ?? '';
            if (data['reasoning'] != null) {
              _askStreamingReasoning = data['reasoning']!;
              if (_history.isNotEmpty) {
                _history[_history.length - 1]['reasoning'] = data['reasoning']!;
              }
            }
          });
          _scrollToBottom();
        }
      },
      onDone: (data) async {
        if (!_askInterrupted) {
          setState(() {
            _asking = false;
            _askStreaming = '';
            _askStreamingReasoning = '';
            if (data['reasoning'] != null && _history.isNotEmpty) {
              _history[_history.length - 1]['reasoning'] = data['reasoning']!;
            }
          });

          final systemPrompt = await PromptService.getActivePromptContent(PromptCategory.qa);
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // 顶部工具栏区（只保留返回和标题）
                    Container(
                      height: 52,
                      color: context.cardBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          // 返回按钮
                          Container(
                            decoration: BoxDecoration(
                              color: context.cardBackgroundColor,
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
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: context.primaryTextColor,
                              ),
                              onPressed: () => Navigator.of(context).maybePop(),
                              tooltip: '返回',
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.primaryTextColor,
                            ),
                          ),
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
                            final isLast = i == _history.length - 1;
                            // 如果正在流式输出，最后一条的 answer 不渲染（只渲染流式）
                            final showAnswer = h['a'] != null && h['a']!.isNotEmpty && (!(_asking && isLast));
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
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF2D5A2B)  // 深色模式下的深绿色
                                                : Colors.green[50],        // 浅色模式下的浅绿色
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? const Color(0xFF4CAF50)  // 深色模式下的绿色边框
                                                  : Colors.green[100]!,     // 浅色模式下的浅绿色边框
                                            ),
                                          ),
                                          child: EnhancedMarkdown(data: h['q'] ?? ''),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFF2D5A2B)  // 深色模式下的深绿色
                                            : const Color(0xFFE8F5E9), // 浅色模式下的浅绿色
                                        child: Icon(
                                          Icons.person,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF4CAF50)  // 深色模式下的绿色图标
                                              : Colors.green,           // 浅色模式下的绿色图标
                                        ),
                                      ),
                                    ],
                                  ),
                                if (showAnswer)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTapDown: (details) {
                                          _showModelTooltip(context, details.globalPosition);
                                        },
                                        child: CircleAvatar(
                                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF37474F)    // 深色模式下的深蓝灰色
                                              : Colors.blueGrey[50],       // 浅色模式下的浅蓝灰色
                                          child: Icon(
                                            Icons.smart_toy,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF90A4AE)  // 深色模式下的蓝灰色图标
                                                : Colors.blueGrey,         // 浅色模式下的蓝灰色图标
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (h['reasoning'] != null && h['reasoning']!.isNotEmpty)
                                              _ReasoningCollapse(
                                                content: h['reasoning']!,
                                                initiallyExpanded: false, // 历史消息默认收缩
                                              ),
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? const Color(0xFF1E3A8A)  // 深色模式下的深蓝色
                                                    : Colors.blue[50],         // 浅色模式下的浅蓝色
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? const Color(0xFF3B82F6)  // 深色模式下的蓝色边框
                                                      : Colors.blue[100]!,      // 浅色模式下的浅蓝色边框
                                                ),
                                              ),
                                              child: EnhancedMarkdown(data: h['a'] ?? ''),
                                            ),
                                          ],
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
                                GestureDetector(
                                  onTapDown: (details) {
                                    _showModelTooltip(context, details.globalPosition);
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF37474F)    // 深色模式下的深蓝灰色
                                        : Colors.blueGrey[50],       // 浅色模式下的浅蓝灰色
                                    child: Icon(
                                      Icons.smart_toy,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF90A4AE)  // 深色模式下的蓝灰色图标
                                          : Colors.blueGrey,         // 浅色模式下的蓝灰色图标
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 显示流式reasoning，默认展开
                                      if (_askStreamingReasoning.isNotEmpty)
                                        _ReasoningCollapse(
                                          content: _askStreamingReasoning,
                                          initiallyExpanded: true,
                                          hasMainContent: _askStreaming.isNotEmpty,
                                        ),
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF374151)  // 深色模式下的深灰色
                                              : Colors.grey[100],        // 浅色模式下的浅灰色
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF6B7280)  // 深色模式下的灰色边框
                                                : Colors.grey[200]!,       // 浅色模式下的浅灰色边框
                                          ),
                                        ),
                                        child: EnhancedMarkdown(data: _askStreaming.isEmpty ? 'AI 正在思考...' : _askStreaming),
                                      ),
                                    ],
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
                      color: context.cardBackgroundColor,
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
                                // 构建结构化的日记内容
                                final buffer = StringBuffer();

                                // 添加summary部分（可以后续扩展为AI生成的摘要）
                                buffer.writeln('#${DateTime.now().toString().split(' ')[0]}');
                                buffer.writeln();

                                // 添加每轮对话
                                for (int i = 0; i < _history.length; i++) {
                                  final h = _history[i];
                                  if (h['q']?.isNotEmpty == true || h['a']?.isNotEmpty == true) {
                                    buffer.writeln('## Round${i + 1}');
                                    buffer.writeln();

                                    if (h['q']?.isNotEmpty == true) {
                                      buffer.writeln('### Q');
                                      buffer.writeln(h['q']!);
                                      buffer.writeln();
                                    }

                                    if (h['a']?.isNotEmpty == true) {
                                      buffer.writeln('### A');
                                      buffer.writeln(h['a']!);
                                      buffer.writeln();
                                    }
                                  }
                                }

                                final content = buffer.toString();
                                try {
                                  // 覆盖当天的日记文件
                                  await MarkdownService.overwriteDailyDiary(content);
                                  final fileName = MarkdownService.getDiaryFileName();
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
                      color: context.cardBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF374151)  // 深色模式下的深灰色
                                    : Colors.grey[100],        // 浅色模式下的浅灰色
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
                                  hintText: '记下现在的想法...',
                                  hintStyle: TextStyle(color: context.secondaryTextColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

// Reasoning折叠显示组件
class _ReasoningCollapse extends StatefulWidget {
  final String content;
  final bool initiallyExpanded;
  final bool hasMainContent; // 是否有主要内容

  const _ReasoningCollapse({
    required this.content,
    this.initiallyExpanded = false,
    this.hasMainContent = false,
  });

  @override
  State<_ReasoningCollapse> createState() => _ReasoningCollapseState();
}

class _ReasoningCollapseState extends State<_ReasoningCollapse> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(_ReasoningCollapse oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当有主要内容输出时，自动收缩reasoning
    if (widget.hasMainContent && _expanded && widget.initiallyExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _expanded = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: context.secondaryTextColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '模型思考过程',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_expanded)
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF374151)  // 深色模式下的深灰色
                    : Colors.grey[100],        // 浅色模式下的浅灰色
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.content,
                style: TextStyle(
                  fontSize: 12,
                  color: context.secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
