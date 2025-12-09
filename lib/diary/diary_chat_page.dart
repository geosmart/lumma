import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../generated/l10n/app_localizations.dart';
import '../diary/chat_history_service.dart';
import '../diary/diary_qa_title_service.dart';
import '../diary/diary_chat_service.dart';
import '../config/theme_service.dart';
import '../diary/diary_file_list_page.dart';
import '../widgets/enhanced_markdown.dart';
import '../widgets/debug_request_dialog.dart';
import '../diary/diary_content_service.dart';
import '../dao/diary_dao.dart';
import '../util/storage_service.dart';
import 'dart:io';

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
  bool _extractingCategory = false; // 是否正在提取分类和标题
  String? _extractingCategoryMsg; // 正在提取时的提示
  bool _lastSaved = false; // 标记最后一条是否已保存

  @override
  void initState() {
    super.initState();
    _loadCurrentModelName();
    _loadTodayHistory();
  }

  // Load current model name
  void _loadCurrentModelName() async {
    final modelName = await DiaryChatService.loadCurrentModelName(context);
    setState(() {
      _currentModelName = modelName;
    });
  }

  // 加载当天非日总结的日记内容到聊天历史
  Future<void> _loadTodayHistory() async {
    try {
      final diaryDir = await StorageService.getDiaryDirPath();
      final fileName = DiaryDao.getDiaryFileName();
      final filePath = '$diaryDir/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        // 解析并过滤掉category为日总结的内容
        final entries = DiaryDao.parseDiaryContent(context, content)
            .where((e) => (e.category?.trim() != '日总结' && e.title.trim() != '日总结'))
            .toList();
        // 按时间升序排序
        entries.sort((a, b) {
          final t1 = a.time ?? '';
          final t2 = b.time ?? '';
          return t1.compareTo(t2);
        });
        setState(() {
          _history = entries.map((e) => e.toMap()).toList();
        });
        // setState后再滚动到底部，确保渲染完成
        _scrollToBottom(initial: true);
      }
    } catch (e) {
      print('加载当天日记历史失败: $e');
    }
  }

  // Automatically extract category and save conversation to diary file
  Future<void> _extractCategoryAndSave({bool forceDefault = false}) async {
    setState(() {
      _extractingCategory = true;
      _extractingCategoryMsg = '${AppLocalizations.of(context)!.aiSummary}...';
      _lastSaved = false;
    });
    try {
      print('[SAVE] _extractCategoryAndSave called');
      await DiaryChatService.extractCategoryAndSave(context, _history, forceDefault: forceDefault);
      setState(() {
        _extractingCategory = false;
        _extractingCategoryMsg = null;
        _lastSaved = true;
      });
      print('[SAVE] _extractCategoryAndSave completed successfully');
      // 不再弹窗提示保存成功
    } catch (e) {
      print('[SAVE] _extractCategoryAndSave failed: $e');
      setState(() {
        _extractingCategory = false;
        _extractingCategoryMsg = null;
        _lastSaved = false;
      });
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Text(
              _currentModelName.isEmpty ? AppLocalizations.of(context)!.loading : _currentModelName,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
            // 确保对话历史完整且未被中断
            if (_history.isNotEmpty &&
                _history.last['q']?.isNotEmpty == true &&
                _history.last['a']?.isNotEmpty == true &&
                !_askInterrupted) {
              print('[SAVE] Starting auto-save process...');
              await _extractCategoryAndSave();
              print('[SAVE] Auto-save process completed');
            } else {
              print('[SAVE] Skipping auto-save: history empty or incomplete');
            }
          }
        }
      },
      onError: (err) async {
        if (!_askInterrupted) {
          final errorMsg = DiaryChatService.parseErrorMessage(err);
          setState(() {
            _asking = false;
            _askStreaming = errorMsg;
          });
          // Add log printing for error information
          print('[LLM] Error: $err');

          // Show configuration error dialog if it's a configuration-related error
          if (DiaryChatService.isLlmConfigurationError(errorMsg)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DiaryChatService.showConfigurationErrorDialog(context, err);
            });
          }
          // 新增：报错时也保存日记内容，使用默认分类和内容分析
          if (_history.isNotEmpty && _history.last['q']?.isNotEmpty == true) {
            print('[SAVE] Error occurred, saving with default category/analysis...');
            await _extractCategoryAndSave(forceDefault: true);
            print('[SAVE] Error save process completed');
          }
        }
      },
    );
  }

  void _scrollToBottom({bool initial = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_scrollController.hasClients) {
        if (initial) {
          // For initial load, add a small delay to ensure layout is fully complete
          await Future.delayed(const Duration(milliseconds: 50));
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          // For subsequent scrolls, use animation
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
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
                              icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.primaryTextColor),
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
                            return SizedBox.shrink();
                          }
                          if (i < _history.length) {
                            final h = _history[i];
                            final isLast = i == _history.length - 1;
                            final showAnswer = h['a'] != null && h['a']!.isNotEmpty && (!(_asking && isLast));
                            // 新增：对话时间分割条
                            String? timeLabel;
                            final curTime = h['time'];
                            if (curTime != null && curTime.isNotEmpty) {
                              // 仅在首条或与上一条时间不同（分钟粒度）时显示
                              bool showTime = true;
                              if (i > 0) {
                                final prevTime = _history[i - 1]['time'];
                                if (prevTime != null && prevTime.isNotEmpty) {
                                  // 只比较到分钟
                                  final curMinute = curTime.length >= 16 ? curTime.substring(0, 16) : curTime;
                                  final prevMinute = prevTime.length >= 16 ? prevTime.substring(0, 16) : prevTime;
                                  if (curMinute == prevMinute) showTime = false;
                                }
                              }
                              if (showTime) {
                                // 只显示HH:mm
                                String displayTime = curTime.length >= 16 ? curTime.substring(11, 16) : curTime;
                                timeLabel = displayTime;
                              }
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (timeLabel != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.grey[800]
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            timeLabel,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey[300]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (h['q'] != null && h['q']!.isNotEmpty)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircleAvatar(
                                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                                              ? const Color(0xFF2D5A2B)
                                              : const Color(0xFFE8F5E9),
                                          child: Icon(
                                            Icons.person,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF4CAF50)
                                                : Colors.green,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                                              minWidth: 48,
                                            ),
                                            child: IntrinsicWidth(
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    margin: const EdgeInsets.only(bottom: 4, right: 32),
                                                    padding: const EdgeInsets.all(14),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? const Color(0xFF2D5A2B)
                                                          : Colors.green[50],
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: Theme.of(context).brightness == Brightness.dark
                                                            ? const Color(0xFF4CAF50)
                                                            : Colors.green[100]!,
                                                      ),
                                                    ),
                                                    child: EnhancedMarkdown(data: h['q'] ?? ''),
                                                  ),
                                                  Positioned(
                                                    right: 0, // 修复在Android端气泡和复制按钮重叠问题
                                                    bottom: 8, // 调整为更贴近气泡底部
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: IconButton(
                                                        icon: const Icon(Icons.copy, size: 16),
                                                        tooltip: '复制',
                                                        onPressed: () {
                                                          Clipboard.setData(ClipboardData(text: h['q'] ?? ''));
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(content: Text('已复制'), duration: Duration(milliseconds: 800)),
                                                          );
                                                        },
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 32),
                                    ],
                                  ),
                                if (showAnswer)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                                              minWidth: 48,
                                            ),
                                            child: IntrinsicWidth(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (h['reasoning'] != null && h['reasoning']!.isNotEmpty)
                                                    _ReasoningCollapse(
                                                      content: h['reasoning']!,
                                                      initiallyExpanded: false,
                                                    ),
                                                  // 删除a的气泡外复制按钮
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Stack(
                                                        children: [
                                                          Container(
                                                            margin: const EdgeInsets.only(bottom: 12),
                                                            padding: const EdgeInsets.all(14),
                                                            decoration: BoxDecoration(
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? const Color(0xFF1E3A8A)
                                                                  : Colors.blue[50],
                                                              borderRadius: BorderRadius.circular(16),
                                                              border: Border.all(
                                                                color: Theme.of(context).brightness == Brightness.dark
                                                                    ? const Color(0xFF3B82F6)
                                                                    : Colors.blue[100]!,
                                                              ),
                                                            ),
                                                            child: Text(h['a'] ?? '', style: TextStyle(fontSize: 14, color: context.primaryTextColor)),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  // 新增：显示AI总结的title和category及已保存角标（同一行，右对齐）
                                                  if ((h['title']?.isNotEmpty == true || h['category']?.isNotEmpty == true))
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 2, bottom: 4),
                                                      child: Row(
                                                        children: [
                                                          if (h['title']?.isNotEmpty == true)
                                                            Flexible(
                                                              child: Text(
                                                                h['title']!,
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Theme.of(context).brightness == Brightness.dark
                                                                      ? Colors.grey[400]
                                                                      : Colors.grey[500],
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          if (h['category']?.isNotEmpty == true)
                                                            Container(
                                                              margin: const EdgeInsets.only(left: 8),
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: DiaryContentService.getCategoryColors(h['category']!)['background'],
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: DiaryContentService.getCategoryColors(h['category']!)['border']!),
                                                              ),
                                                              child: Text(
                                                                h['category']!,
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  color: DiaryContentService.getCategoryColors(h['category']!)['text'],
                                                                ),
                                                              ),
                                                            ),
                                                          // 右侧对齐显示已保存角标
                                                          if (_lastSaved && isLast && !_extractingCategory)
                                                            Expanded(
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.end,
                                                                children: [
                                                                  Icon(Icons.check_circle, size: 14, color: Colors.green[400]),
                                                                  const SizedBox(width: 4),
                                                                  Text('已保存', style: TextStyle(fontSize: 11, color: Colors.green[400], fontWeight: FontWeight.w500)),
                                                                ],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  // 正在总结loading
                                                  if (_extractingCategory && isLast)
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 2, bottom: 4),
                                                      child: Row(
                                                        children: [
                                                          SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Text(
                                                            _extractingCategoryMsg ?? '',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: Theme.of(context).brightness == Brightness.dark
                                                                  ? Colors.grey[400]
                                                                  : Colors.grey[500],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: GestureDetector(
                                          onTapDown: (details) {
                                            _showModelTooltip(context, details.globalPosition);
                                          },
                                          child: CircleAvatar(
                                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF37474F)
                                                : Colors.blueGrey[50],
                                            child: Icon(
                                              Icons.smart_toy,
                                              color: Theme.of(context).brightness == Brightness.dark
                                                  ? const Color(0xFF90A4AE)
                                                  : Colors.blueGrey,
                                            ),
                                          ),
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
                                        ? const Color(0xFF37474F)
                                        : Colors.blueGrey[50],
                                    child: Icon(
                                      Icons.smart_toy,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF90A4AE)
                                          : Colors.blueGrey,
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
                                              ? const Color(0xFF374151) // Dark mode deep grey
                                              : Colors.grey[100], // Light mode light grey
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF6B7280) // Dark mode grey border
                                                : Colors.grey[200]!, // Light mode light grey border
                                          ),
                                        ),
                                        child: Text(
                                          _askStreaming.isEmpty
                                              ? AppLocalizations.of(context)!.aiThinking
                                              : _askStreaming,
                                          style: TextStyle(fontSize: 14, color: context.primaryTextColor),
                                        ),
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
                    // Button area: above input field, only showing debug and diary list buttons
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
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiaryFileListPage()));
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

  const _ReasoningCollapse({required this.content, this.initiallyExpanded = false, this.hasMainContent = false});

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
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 18, color: context.secondaryTextColor),
                const SizedBox(width: 2),
                Text(
                  AppLocalizations.of(context)!.aiSummaryResult,
                  style: TextStyle(fontSize: 12, color: context.secondaryTextColor, fontWeight: FontWeight.w500),
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
                    ? const Color(0xFF374151) // Dark mode deep grey
                    : Colors.grey[100], // Light mode light grey
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.content, style: TextStyle(fontSize: 12, color: context.secondaryTextColor)),
            ),
        ],
      ),
    );
  }
}
