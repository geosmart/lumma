import 'package:flutter/material.dart';
import 'dart:io';
import '../dao/diary_dao.dart';
import '../generated/l10n/app_localizations.dart';

/// Diary content service class, handles business logic for diary content
class DiaryContentService {
  // ====== 随机互斥颜色缓存实现 ======
  static final Map<String, Map<String, Color>> _categoryColorCache = {};
  static final List<List<Color>> _colorPalette = [
    [Colors.blue[50]!, Colors.blue[200]!, Colors.blue[700]!],
    [Colors.green[50]!, Colors.green[200]!, Colors.green[700]!],
    [Colors.red[50]!, Colors.red[200]!, Colors.red[700]!],
    [Colors.purple[50]!, Colors.purple[200]!, Colors.purple[700]!],
    [Colors.orange[50]!, Colors.orange[200]!, Colors.orange[700]!],
    [Colors.indigo[50]!, Colors.indigo[200]!, Colors.indigo[700]!],
    [Colors.brown[50]!, Colors.brown[200]!, Colors.brown[700]!],
    [Colors.deepPurple[50]!, Colors.deepPurple[200]!, Colors.deepPurple[700]!],
    [Colors.pink[50]!, Colors.pink[200]!, Colors.pink[700]!],
    [Colors.teal[50]!, Colors.teal[200]!, Colors.teal[700]!],
    [Colors.cyan[50]!, Colors.cyan[200]!, Colors.cyan[700]!],
    [Colors.amber[50]!, Colors.amber[200]!, Colors.amber[700]!],
    [Colors.lime[50]!, Colors.lime[200]!, Colors.lime[700]!],
    [Colors.lightBlue[50]!, Colors.lightBlue[200]!, Colors.lightBlue[700]!],
    [Colors.deepOrange[50]!, Colors.deepOrange[200]!, Colors.deepOrange[700]!],
  ];
  static int _colorIndex = 0;

  /// Load diary content
  static Future<Map<String, dynamic>> loadDiaryContent(String fileName) async {
    final diaryDir = await DiaryDao.getDiaryDir();
    final file = File('$diaryDir/$fileName');
    final content = await DiaryDao.readDiaryMarkdown(file);

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

    return {'content': body, 'fullContent': content, 'frontmatter': frontmatter, 'filePath': file.path};
  }

  /// Save diary content
  static Future<void> saveDiaryContent(String content, String fileName) async {
    await DiaryDao.saveDiaryMarkdown(content, fileName: fileName);
  }

  /// Handle saving diary content with daily summary section
  static Future<void> saveOrReplaceDiarySummary(String content, String fileName, BuildContext context) async {
    final diaryDir = await DiaryDao.getDiaryDir();
    final file = File('$diaryDir/$fileName');
    final newSummaryEntry = DiaryDao.formatDiaryContent(
      context: context,
      title: '日总结',
      content: content,
      analysis: '',
      category: '日总结',
    );

    if (!await file.exists()) {
      final newFileContent = '---\n\n$newSummaryEntry';
      await file.writeAsString(newFileContent);
      return;
    }
    final currentContent = await file.readAsString();
    final contentWithoutSummary = DiaryDao.removeDailySummarySection(context, currentContent);
    String finalContent;
    if (contentWithoutSummary.trim().isEmpty) {
      finalContent = '---\n\n$newSummaryEntry';
    } else {
      finalContent = '${contentWithoutSummary.trim()}\n\n$newSummaryEntry';
    }
    await file.writeAsString(finalContent);
  }

  /// Get chat history and sort, placing summary content first
  static List<Map<String, String>> getChatHistoryWithSummaryFirst(BuildContext context, String content) {
    final history = DiaryDao.parseDiaryMarkdownToChatHistory(context, content);
    final summaryItems = <Map<String, String>>[];
    final normalItems = <Map<String, String>>[];
    for (final item in history) {
      if (isSummaryContent(item.q ?? '') || isSummaryContent(item.a ?? '')) {
        summaryItems.add(item.toMap());
      } else {
        normalItems.add(item.toMap());
      }
    }
    return [...summaryItems, ...normalItems];
  }

  /// Determine if content is summary content
  static bool isSummaryContent(String content) {
    final hasObserve = content.contains('#observe');
    final hasGood = content.contains('#good');
    final hasDifficult = content.contains('#difficult');
    final hasDifferent = content.contains('#different');
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
    if (category.trim().isEmpty) {
      // fallback for empty category
      return {'background': Colors.grey[100]!, 'border': Colors.grey[300]!, 'text': Colors.grey[700]!};
    }
    final key = category.trim().toLowerCase();
    if (_categoryColorCache.containsKey(key)) {
      return _categoryColorCache[key]!;
    }
    // 互斥分配颜色
    final colorSet = _colorPalette[_colorIndex % _colorPalette.length];
    _colorIndex++;
    final colorMap = {
      'background': colorSet[0],
      'border': colorSet[1],
      'text': colorSet[2],
    };
    _categoryColorCache[key] = colorMap;
    return colorMap;
  }

  /// Parse summary content and return grouped by categories
  static Map<String, List<String>> parseSummaryContent(String content) {
    // Group summary content by 4 categories
    final Map<String, List<String>> groupedContent = {'observe': [], 'good': [], 'difficult': [], 'different': []};

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
      'observe': {
        'title': AppLocalizations.of(context)!.observeDiscovery,
        'icon': Icons.visibility,
        'color': Colors.blue,
      },
      'good': {'title': AppLocalizations.of(context)!.positiveGains, 'icon': Icons.favorite, 'color': Colors.green},
      'difficult': {
        'title': AppLocalizations.of(context)!.difficultChallenges,
        'icon': Icons.warning,
        'color': Colors.red,
      },
      'different': {
        'title': AppLocalizations.of(context)!.reflectionImprovement,
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
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

  /// Rebuild markdown content from chat history (List<Map<String, String>>)
  static String rebuildContentFromHistory(BuildContext context, List<Map<String, String>> history) {
    return DiaryDao.historyToMarkdown(context, history);
  }
}
