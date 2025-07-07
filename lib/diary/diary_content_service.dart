import 'package:flutter/material.dart';
import 'dart:io';
import '../util/markdown_service.dart';
import '../dao/diary_dao.dart';
import '../generated/l10n/app_localizations.dart';

/// Diary content service class, handles business logic for diary content
class DiaryContentService {
  /// Load diary content
  static Future<Map<String, dynamic>> loadDiaryContent(String fileName) async {
    final diaryDir = await MarkdownService.getDiaryDir();
    final file = File('$diaryDir/$fileName');
    final content = await MarkdownService.readDiaryMarkdown(file);

    // Parse frontmatter
    Map<String, String>? frontmatter;
    String body = content;
    if (content.startsWith('---')) {
      final lines = content.split('\n');
      final endIdx = lines.indexWhere((l) => l.trim() == '---', 1);
      if (endIdx > 0) {
        frontmatter = {};
        for (var i = 1; i < endIdx; i++) {
          final line = lines[i];
          final idx = line.indexOf(':');
          if (idx > 0) {
            final key = line.substring(0, idx).trim();
            final value = line.substring(idx + 1).trim();
            frontmatter[key] = value;
          }
        }
        // Remove frontmatter section
        body = lines.sublist(endIdx + 1).join('\n');
      }
    }

    return {
      'content': body,
      'fullContent': content,
      'frontmatter': frontmatter,
      'filePath': file.path,
    };
  }

  /// Save diary content
  static Future<void> saveDiaryContent(String content, String fileName) async {
    await MarkdownService.saveDiaryMarkdown(content, fileName: fileName);
  }

  /// Get chat history and sort, placing summary content first
  static List<Map<String, String>> getChatHistoryWithSummaryFirst(BuildContext context, String content) {
    final history = DiaryDao.parseDiaryMarkdownToChatHistory(context, content);

    // Separate summary content and normal content
    final summaryItems = <Map<String, String>>[];
    final normalItems = <Map<String, String>>[];

    for (final item in history) {
      if (isSummaryContent(item['q'] ?? '') || isSummaryContent(item['a'] ?? '')) {
        summaryItems.add(item);
      } else {
        normalItems.add(item);
      }
    }

    // Place summary content at the beginning
    return [...summaryItems, ...normalItems];
  }

  /// Determine if content is summary content
  static bool isSummaryContent(String content) {
    // If content contains summary-related tag combinations, it is considered summary content
    final hasObserve = content.contains('#observe');
    final hasGood = content.contains('#good');
    final hasDifficult = content.contains('#difficult');
    final hasDifferent = content.contains('#different');

    // If contains at least 2 main category tags, it is considered summary content
    final count = [hasObserve, hasGood, hasDifficult, hasDifferent].where((x) => x).length;
    return count >= 2;
  }

  /// Determine if time and title should be shown (not shown in daily summary)
  static bool shouldShowTimeAndTitle(Map<String, String> historyItem) {
    final q = historyItem['q'] ?? '';
    final a = historyItem['a'] ?? '';
    return !isSummaryContent(q) && !isSummaryContent(a);
  }

  /// Return corresponding color configuration based on tag type
  static Map<String, Color> getCategoryColors(String category) {
    final lowerCategory = category.toLowerCase();

    // Observation tags - blue
    if (lowerCategory.contains('observe') || lowerCategory.contains('观察') ||
        lowerCategory.contains('环境') || lowerCategory.contains('他人')) {
      return {
        'background': Colors.blue[50]!,
        'border': Colors.blue[200]!,
        'text': Colors.blue[700]!,
      };
    }

    // Positive/good tags - green
    if (lowerCategory.contains('good') || lowerCategory.contains('成就') ||
        lowerCategory.contains('喜悦') || lowerCategory.contains('感恩')) {
      return {
        'background': Colors.green[50]!,
        'border': Colors.green[200]!,
        'text': Colors.green[700]!,
      };
    }

    // Difficult/challenge tags - red
    if (lowerCategory.contains('difficult') || lowerCategory.contains('挑战') ||
        lowerCategory.contains('情绪') || lowerCategory.contains('身体')) {
      return {
        'background': Colors.red[50]!,
        'border': Colors.red[200]!,
        'text': Colors.red[700]!,
      };
    }

    // Improvement/different tags - purple
    if (lowerCategory.contains('different') || lowerCategory.contains('觉察') ||
        lowerCategory.contains('改进')) {
      return {
        'background': Colors.purple[50]!,
        'border': Colors.purple[200]!,
        'text': Colors.purple[700]!,
      };
    }

    // Daily summary - orange (special handling)
    if (lowerCategory.contains('日总结') || lowerCategory.contains('总结') ||
        lowerCategory == '## 日总结') {
      return {
        'background': Colors.orange[50]!,
        'border': Colors.orange[200]!,
        'text': Colors.orange[700]!,
      };
    }

    // Work related - indigo
    if (lowerCategory.contains('工作') || lowerCategory.contains('职场') ||
        lowerCategory.contains('meeting') || lowerCategory.contains('项目')) {
      return {
        'background': Colors.indigo[50]!,
        'border': Colors.indigo[200]!,
        'text': Colors.indigo[700]!,
      };
    }

    // Life related - brown
    if (lowerCategory.contains('生活') || lowerCategory.contains('日常') ||
        lowerCategory.contains('家庭') || lowerCategory.contains('休闲')) {
      return {
        'background': Colors.brown[50]!,
        'border': Colors.brown[200]!,
        'text': Colors.brown[700]!,
      };
    }

    // Study related - deep purple
    if (lowerCategory.contains('学习') || lowerCategory.contains('读书') ||
        lowerCategory.contains('知识') || lowerCategory.contains('技能')) {
      return {
        'background': Colors.deepPurple[50]!,
        'border': Colors.deepPurple[200]!,
        'text': Colors.deepPurple[700]!,
      };
    }

    // Health related - pink
    if (lowerCategory.contains('健康') || lowerCategory.contains('运动') ||
        lowerCategory.contains('饮食') || lowerCategory.contains('锻炼')) {
      return {
        'background': Colors.pink[50]!,
        'border': Colors.pink[200]!,
        'text': Colors.pink[700]!,
      };
    }

    // Other tags - default teal
    return {
      'background': Colors.teal[50]!,
      'border': Colors.teal[200]!,
      'text': Colors.teal[700]!,
    };
  }

  /// Parse summary content and return grouped by categories
  static Map<String, List<String>> parseSummaryContent(String content) {
    // Group summary content by 4 categories
    final Map<String, List<String>> groupedContent = {
      'observe': [],
      'good': [],
      'difficult': [],
      'different': [],
    };

    // Parse content and group
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;

      if (trimmedLine.contains('#observe')) {
        groupedContent['observe']!.add(trimmedLine);
      } else if (trimmedLine.contains('#good')) {
        groupedContent['good']!.add(trimmedLine);
      } else if (trimmedLine.contains('#difficult')) {
        groupedContent['difficult']!.add(trimmedLine);
      } else if (trimmedLine.contains('#different')) {
        groupedContent['different']!.add(trimmedLine);
      }
    }

    return groupedContent;
  }

  /// Get summary group information
  static Map<String, Map<String, dynamic>> getSummaryGroupInfo(BuildContext context) {
    return {
      'observe': {'title': AppLocalizations.of(context)!.observeDiscovery, 'icon': Icons.visibility, 'color': Colors.blue},
      'good': {'title': AppLocalizations.of(context)!.positiveGains, 'icon': Icons.favorite, 'color': Colors.green},
      'difficult': {'title': AppLocalizations.of(context)!.difficultChallenges, 'icon': Icons.warning, 'color': Colors.red},
      'different': {'title': AppLocalizations.of(context)!.reflectionImprovement, 'icon': Icons.psychology, 'color': Colors.purple},
    };
  }

  /// Clean summary item content (remove tags and markers)
  static String cleanSummaryItemContent(String content) {
    final tagRegex = RegExp(r'(#[^\s#]+)');

    // Remove all tags, only show plain text
    final cleanContent = content.replaceAll(tagRegex, '').trim();

    // Remove leading * or - marker
    final finalContent = cleanContent.replaceFirst(RegExp(r'^[\*\-]\s*'), '');

    return finalContent;
  }

  /// Parse tags in content
  static bool hasTagsInContent(String content) {
    final tagRegex = RegExp(r'(#[^\s#]+)');
    return tagRegex.hasMatch(content);
  }

  /// Get tag matches in content
  static Iterable<RegExpMatch> getTagMatches(String content) {
    final tagRegex = RegExp(r'(#[^\s#]+)');
    return tagRegex.allMatches(content);
  }
}
