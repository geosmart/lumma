import 'package:flutter/material.dart';
import '../config/theme_service.dart';
import '../util/ai_service.dart';
import '../util/prompt_util.dart';
import '../model/enums.dart';
import '../dao/diary_dao.dart';
import '../util/markdown_service.dart';

/// AI 结果页面公共组件
class AiResultPage extends StatefulWidget {
  final String title;
  final VoidCallback onBack;
  final String? processingText;
  final String? hintText;
  final Future<String?> Function() getContent; // 获取内容的回调

  const AiResultPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.getContent,
    this.processingText,
    this.hintText,
  });

  @override
  State<AiResultPage> createState() => _AiResultPageState();
}

class _AiResultPageState extends State<AiResultPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startSummaryStream(); // 自动开始AI总结
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSummaryStream() async {
    final content = await widget.getContent();
    if (content == null) return;

    setState(() {
      _isProcessing = true;
      _controller.text = '';
    });

    try {
      final systemPrompt = await getActivePromptContent(PromptCategory.qa);
      final messages = AiService.buildMessages(
        systemPrompt: systemPrompt,
        history: [],
        userInput: content,
      );

      await AiService.askStream(
        messages: messages,
        onDelta: (data) {
          if (mounted) {
            setState(() {
              _controller.text = data['content'] ?? '';
            });
          }
        },
        onDone: (finalResult) {
          if (mounted) {
            setState(() {
              _controller.text = finalResult['content'] ?? '';
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

  Future<void> _handleAction(String action) async {
    try {
      switch (action) {
        case 'regenerate':
          await _startSummaryStream();
          break;
        case 'save':
          final editedResult = _controller.text;
          final content = DiaryDao.formatDiaryContent(
            title: '日总结',
            content: editedResult,
            analysis: '',
            category: '',
          );
          await MarkdownService.saveOrUpdateDailySummary(content);
          widget.onBack(); // 返回上一页
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('日总结已保存到日记')),
            );
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.cardBackgroundColor,
        title: Text(widget.title, style: TextStyle(color: context.primaryTextColor)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primaryTextColor),
          onPressed: widget.onBack,
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
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新生成'),
                  onPressed: _isProcessing ? null : () => _handleAction('regenerate'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                  onPressed: _isProcessing ? null : () => _handleAction('save'),
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
                    Text(
                      widget.processingText ?? 'AI 正在生成中...',
                      style: TextStyle(color: context.secondaryTextColor)
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TextField(
                controller: _controller,
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
                  hintText: widget.hintText ?? 'AI 生成的内容将显示在这里...',
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
}
