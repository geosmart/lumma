import 'package:flutter/widgets.dart';
import '../generated/l10n/app_localizations.dart';

class DiaryDao {
  /// Common diary content formatting method
  /// [title] Diary title (e.g., question or AI-generated title)
  /// [answer] User answer or AI analysis
  /// [category] Category (optional)
  /// [time] Time (optional, defaults to current time)
  /// [content] Diary content (e.g., the question itself)
  /// [analysis] Content analysis (e.g., AI answer, optional)
  static String formatDiaryContent({
    required BuildContext context,
    required String title,
    required String content,
    required String analysis,
    String? category,
    String? time,
    bool useEnglish = false,
  }) {
    final buffer = StringBuffer();
    // 1. Title
    buffer.writeln('## $title');
    buffer.writeln();
    // 2. Time
    final now = DateTime.now();
    final timeStr = time ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    buffer.writeln(AppLocalizations.of(context)!.time); // i18n for '时间'
    buffer.writeln(timeStr);
    buffer.writeln();
    // 3. Category
    buffer.writeln(AppLocalizations.of(context)!.category); // i18n for '分类'
    buffer.writeln(category ?? '');
    buffer.writeln();
    // 4. Diary content
    buffer.writeln(AppLocalizations.of(context)!.diaryContent); // i18n for '日记内容'
    buffer.writeln(content);
    buffer.writeln();
    // 5. Content analysis
    buffer.writeln(AppLocalizations.of(context)!.contentAnalysis); // i18n for '内容分析'
    buffer.writeln(analysis);
    buffer.writeln();
    // Separator
    buffer.writeln('---');
    buffer.writeln();
    return buffer.toString();
  }

  /// Parse markdown to chat history, returns List<Map<String, String>>
  /// Each round contains: title, time, category, q, a
  static List<Map<String, String>> parseDiaryMarkdownToChatHistory(BuildContext context, String content) {
    final lines = content.split('\n');
    final List<Map<String, String>> chatHistory = [];
    Map<String, String> currentItem = {};
    String? currentSection;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('## ')) {
        // New round, save previous round first
        if (currentItem.isNotEmpty) chatHistory.add(currentItem);
        currentItem = {'title': trimmed.substring(3)};
        currentSection = null;
      } else if (trimmed.startsWith('### ')) {
        // Mark current section
        if (trimmed.contains(AppLocalizations.of(context)!.time) || trimmed.contains('Time')) {
          currentSection = 'time';
        } else if (trimmed.contains(AppLocalizations.of(context)!.category) || trimmed.contains('Category')) {
          currentSection = 'category';
        } else if (trimmed.contains(AppLocalizations.of(context)!.diaryContent) || trimmed.contains('Diary Content')) {
          currentSection = 'q';
        } else if (trimmed.contains(AppLocalizations.of(context)!.contentAnalysis) || trimmed.contains('Content Analysis')) {
          currentSection = 'a';
        } else {
          currentSection = null;
        }
      } else if (trimmed == '---') {
        // End of round
        if (currentItem.isNotEmpty) chatHistory.add(currentItem);
        currentItem = {};
        currentSection = null;
      } else if (currentSection != null && trimmed.isNotEmpty) {
        currentItem[currentSection] = trimmed;
      }
    }
    if (currentItem.isNotEmpty) chatHistory.add(currentItem);
    return chatHistory;
  }
}
