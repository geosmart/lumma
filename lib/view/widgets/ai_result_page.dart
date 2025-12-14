import 'package:flutter/material.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/service/ai_service.dart';
import 'package:lumma/util/prompt_util.dart';
import 'package:lumma/model/enums.dart';
import 'package:lumma/dao/diary_dao.dart';
import 'package:lumma/service/diary_content_service.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';

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
    final processedContent = DiaryDao.extractPlainDiaryEntries(context, content);
    setState(() {
      _isProcessing = true;
      _controller.text = '';
    });

    try {
      final systemPrompt = await getActivePromptContent(PromptCategory.summary);
      final messages = AiService.buildMessages(
        systemPrompt: systemPrompt,
        history: [],
        userInput: processedContent, // Use processed content without daily summary
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
              SnackBar(content: Text('${AppLocalizations.of(context)!.aiSummaryFailed}: ${error.toString()}')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.aiSummaryFailed}: ${e.toString()}')));
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

          await DiaryContentService.saveOrReplaceDiarySummary(editedResult, widget.fileName!, context);
          print('AI总结保存到指定文件: ${widget.fileName}');

          // Show success message first
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.dailySummarySaved)));
          }

          // Return to previous page with success result to trigger refresh
          Navigator.of(context).pop(true);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context)!.operationFailed}: ${e.toString()}')));
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
                    const SizedBox(width: 10),
                    Text(
                      widget.processingText ?? AppLocalizations.of(context)!.aiGenerating,
                      style: TextStyle(color: context.secondaryTextColor, fontSize: 15, letterSpacing: 0.2),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBackgroundColor, // 修正：不加透明度，保证主题一致
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontSize: 17,
                    height: 1.7, // 行高
                    letterSpacing: 0.4, // 字间距
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.borderColor, width: 1.1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.borderColor, width: 1.1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.3),
                    ),
                    hintText: widget.hintText ?? AppLocalizations.of(context)!.aiContentPlaceholder,
                    hintStyle: TextStyle(color: context.secondaryTextColor, fontSize: 16, letterSpacing: 0.3),
                    fillColor: context.cardBackgroundColor, // 修正：不加透明度
                    filled: true,
                    contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    isDense: true,
                    alignLabelWithHint: true,
                  ),
                  strutStyle: const StrutStyle(height: 1.7, forceStrutHeight: true),
                  cursorColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 22),
            // Action button area, placed at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(AppLocalizations.of(context)!.regenerate, style: const TextStyle(fontSize: 16)),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: context.cardBackgroundColor,
                      foregroundColor: context.primaryTextColor,
                      elevation: 0.5,
                      side: BorderSide(color: context.borderColor, width: 1),
                    ),
                    onPressed: _isProcessing ? null : () => _handleAction('regenerate'),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(fontSize: 16)),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 1.5,
                    ),
                    onPressed: _isProcessing ? null : () => _handleAction('save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
