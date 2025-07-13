import 'package:flutter/material.dart';
import '../config/theme_service.dart';
import '../util/ai_service.dart';
import '../util/prompt_util.dart';
import '../model/enums.dart';
import '../dao/diary_dao.dart';
import '../util/markdown_service.dart';
import '../diary/diary_content_service.dart';
import '../generated/l10n/app_localizations.dart';

/// AI result page common component
class AiResultPage extends StatefulWidget {
  final String title;
  final VoidCallback onBack;
  final String? processingText;
  final String? hintText;
  final Future<String?> Function() getContent; // Callback to get content
  final String? fileName; // Add fileName parameter for saving to specific file

  const AiResultPage({
    super.key,
    required this.title,
    required this.onBack,
    required this.getContent,
    this.processingText,
    this.hintText,
    this.fileName, // Add fileName parameter
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
    _startSummaryStream(context); // Automatically start AI summary
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startSummaryStream(BuildContext context) async {
    final content = await widget.getContent();
    if (content == null) return;
    final processedContent = DiaryDao.removeDailySummarySection(
      context,
      content,
    );
    setState(() {
      _isProcessing = true;
      _controller.text = '';
    });

    try {
      final systemPrompt = await getActivePromptContent(PromptCategory.summary);
      final messages = AiService.buildMessages(
        systemPrompt: systemPrompt,
        history: [],
        userInput:
            processedContent, // Use processed content without daily summary
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
              SnackBar(
                content: Text(
                  '${AppLocalizations.of(context)!.aiSummaryFailed}: ${error.toString()}',
                ),
              ),
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
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.aiSummaryFailed}: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleAction(String action) async {
    try {
      switch (action) {
        case 'regenerate':
          await _startSummaryStream(context);
          break;
        case 'save':
          final editedResult = _controller.text;

          await DiaryContentService.saveOrReplaceDiarySummary(
            editedResult,
            widget.fileName!,
            context,
          );
          print('AI总结保存到指定文件: ${widget.fileName}');

          // Show success message first
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.dailySummarySaved),
              ),
            );
          }

          // Return to previous page with success result to trigger refresh
          Navigator.of(context).pop(true);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.operationFailed}: ${e.toString()}',
            ),
          ),
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
        title: Text(
          widget.title,
          style: TextStyle(color: context.primaryTextColor),
        ),
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
            // Action button area, placed above the input field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.regenerate),
                  onPressed: _isProcessing
                      ? null
                      : () => _handleAction('regenerate'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(AppLocalizations.of(context)!.save),
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
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.processingText ??
                          AppLocalizations.of(context)!.aiGenerating,
                      style: TextStyle(color: context.secondaryTextColor),
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
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  hintText:
                      widget.hintText ??
                      AppLocalizations.of(context)!.aiContentPlaceholder,
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
