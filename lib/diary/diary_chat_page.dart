import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../diary/chat_history_service.dart';
import '../diary/diary_qa_title_service.dart';
import '../diary/diary_chat_service.dart';
import '../config/theme_service.dart';
import '../diary/diary_file_list_page.dart';
import '../widgets/enhanced_markdown.dart';
import '../widgets/debug_request_dialog.dart';

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
  String _currentModelName = ''; // Current model name in use

  @override
  void initState() {
    super.initState();
    _loadCurrentModelName(); // Load current model name
  }

  // Load current model name
  void _loadCurrentModelName() async {
    final modelName = await DiaryChatService.loadCurrentModelName(context);
    setState(() {
      _currentModelName = modelName;
    });
  }

  // Automatically extract category and title and save conversation to diary file
  Future<void> _extractCategoryAndSave() async {
    await DiaryChatService.extractCategoryAndSave(context, _history);
    // Trigger UI update
    setState(() {});
  }

  // Show model name tooltip
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
              _currentModelName.isEmpty ? AppLocalizations.of(context)!.loading : _currentModelName,
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

    // Auto hide after 2 seconds
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

    // Build request and get debug information
    final raw = await DiaryChatService.buildChatRequest(context, _history, userInput);
    final prettyJson = DiaryChatService.formatRequestJson(raw);
    setState(() {
      _lastRequestJson = prettyJson;
    });

    // Send AI request
    await DiaryChatService.sendAiRequest(
      history: _history,
      userInput: userInput,
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
          // Add log printing for LLM response content
          print('[LLM] Delta: \\n${data.toString()}');
          _scrollToBottom();
        }
      },
      onDone: (data) async {
        // Check if it is a JSON error returned by the API (such as 401)
        final errorMsg = DiaryChatService.checkApiError(data);
        if (!_askInterrupted) {
          setState(() {
            _asking = false;
            _askStreaming = errorMsg ?? '';
            _askStreamingReasoning = '';
            if (data['reasoning'] != null && _history.isNotEmpty) {
              _history[_history.length - 1]['reasoning'] = data['reasoning']!;
            }
          });
          if (errorMsg == null) {
            // Update debug information
            final raw = await DiaryChatService.buildChatRequest(context, _history, '');
            final prettyJson = DiaryChatService.formatRequestJson(raw);
            setState(() {
              _lastRequestJson = prettyJson;
            });
            // Add log printing for final LLM response content
            print('[LLM] Done: \n$data');
            _scrollToBottom();

            // Automatically extract category and save to diary file after AI response completion
            _extractCategoryAndSave();
          }
        }
      },
      onError: (err) {
        if (!_askInterrupted) {
          final errorMsg = DiaryChatService.parseErrorMessage(err);
          setState(() {
            _asking = false;
            _askStreaming = errorMsg;
          });
          // Add log printing for error information
          print('[LLM] Error: $err');
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

  void _sendAnswer() async {
    final userInput = _ctrl.text.trim();
    if (userInput.isEmpty) return;
    setState(() {
      _history = ChatHistoryService.addHistory(_history, question: userInput, answer: '');
      _ctrl.clear();
    });
    _askNext();
    _scrollToBottom();

    // User message is not saved immediately, wait for AI response to save
    // Save logic is handled in _extractCategoryAndSave()
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getDiaryQaTitle(context),
      builder: (context, snapshot) {
        final title = snapshot.data ?? AppLocalizations.of(context)!.chatDiaryTitle;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Top toolbar area (only back and title)
                    Container(
                      height: 52,
                      color: context.cardBackgroundColor,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          // Return button
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
                              tooltip: AppLocalizations.of(context)!.back,
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
                    // Immersive full-screen chat main UI, no AppBar
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _history.length + (_asking ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (_summary != null && i == 0) {
                            return SizedBox.shrink(); // Do not show AI summary/edit area in full-screen chat
                          }
                          if (i < _history.length) {
                            final h = _history[i];
                            final isLast = i == _history.length - 1;
                            // If streaming output, do not render the last answer (only render streaming)
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
                                                ? const Color(0xFF2D5A2B)  // Dark mode deep green
                                                : Colors.green[50],        // Light mode light green
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? const Color(0xFF4CAF50)  // Dark mode green border
                                                  : Colors.green[100]!,     // Light mode light green border
                                            ),
                                          ),
                                          child: EnhancedMarkdown(data: h['q'] ?? ''),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? const Color(0xFF2D5A2B)  // Dark mode deep green
                                            : const Color(0xFFE8F5E9), // Light mode light green
                                        child: Icon(
                                          Icons.person,
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF4CAF50)  // Dark mode green icon
                                              : Colors.green,           // Light mode green icon
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
                                              ? const Color(0xFF37474F)    // Dark mode deep blue-grey
                                              : Colors.blueGrey[50],       // Light mode light blue-grey
                                          child: Icon(
                                            Icons.smart_toy,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF90A4AE)  // Dark mode blue-grey icon
                                                : Colors.blueGrey,         // Light mode blue-grey icon
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
                                                initiallyExpanded: false, // History messages collapsed by default
                                              ),
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? const Color(0xFF1E3A8A)  // Dark mode deep blue
                                                    : Colors.blue[50],         // Light mode light blue
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Theme.of(context).brightness == Brightness.dark
                                                      ? const Color(0xFF3B82F6)  // Dark mode blue border
                                                      : Colors.blue[100]!,      // Light mode light blue border
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
                            // AI thinking/streaming output
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTapDown: (details) {
                                    _showModelTooltip(context, details.globalPosition);
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF37474F)    // Dark mode deep blue-grey
                                        : Colors.blueGrey[50],       // Light mode light blue-grey
                                    child: Icon(
                                      Icons.smart_toy,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF90A4AE)  // Dark mode blue-grey icon
                                          : Colors.blueGrey,         // Light mode blue-grey icon
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Show streaming reasoning, expanded by default
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
                                              ? const Color(0xFF374151)  // Dark mode deep grey
                                              : Colors.grey[100],        // Light mode light grey
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF6B7280)  // Dark mode grey border
                                                : Colors.grey[200]!,       // Light mode light grey border
                                          ),
                                        ),
                                        child: EnhancedMarkdown(data: _askStreaming.isEmpty ? AppLocalizations.of(context)!.aiThinking : _askStreaming),
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
                    // Button area: above input field, only showing debug, save, and diary list buttons
                    Container(
                      color: context.cardBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: Row(
                        children: [
                          // Debug button
                          IconButton(
                            icon: const Icon(Icons.bug_report, color: Colors.deepOrange),
                            tooltip: AppLocalizations.of(context)!.debugTooltip,
                            onPressed: () {
                              if (_lastRequestJson != null) {
                                DebugRequestDialog.show(context, _lastRequestJson!);
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                          // Diary list button
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
                    ),
                    // Bottom input bar, floating with rounded corners
                    Container(
                      color: context.cardBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF374151)
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
                                  hintText: AppLocalizations.of(context)!.userInputPlaceholder,
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
                    ),
                  ],
                ),
                // Floating stop button, moved up to avoid toolbar
                if (_asking)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 140, // Move up
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

// Reasoning collapse component
class _ReasoningCollapse extends StatefulWidget {
  final String content;
  final bool initiallyExpanded;
  final bool hasMainContent; // Whether there is main content

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
    // When there is main content output, automatically collapse reasoning
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
                  AppLocalizations.of(context)!.aiSummaryResult,
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
                    ? const Color(0xFF374151)  // Dark mode deep grey
                    : Colors.grey[100],        // Light mode light grey
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
