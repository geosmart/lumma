import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/util/frontmatter_service.dart';
import 'package:lumma/util/storage_service.dart';
import 'package:lumma/service/config_service.dart';

/// Diary entry model for better readability
class DiaryEntry {
  final String title;
  final String? time;
  final String? category;
  final String? q; // diary content (question)
  final String? a; // content analysis (answer)

  DiaryEntry({required this.title, this.time, this.category, this.q, this.a});

  /// Convert from Map<String, String> format
  factory DiaryEntry.fromMap(Map<String, String> map) {
    return DiaryEntry(
      title: map['title'] ?? '',
      time: map['time'],
      category: map['category'],
      q: map['q'],
      a: map['a'],
    );
  }

  /// Convert to Map<String, String> format for compatibility
  Map<String, String> toMap() {
    final map = <String, String>{'title': title};
    if (time != null) map['time'] = time!;
    if (category != null) map['category'] = category!;
    if (q != null) map['q'] = q!;
    if (a != null) map['a'] = a!;
    return map;
  }

  /// Parse time string to DateTime for sorting
  DateTime? get parsedTime {
    if (time == null) return null;
    try {
      final now = DateTime.now();
      final timeParts = time!.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }
}

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
    buffer.writeln('### ${AppLocalizations.of(context)!.time}'); // i18n for '时间'
    buffer.writeln(timeStr);
    buffer.writeln();
    // 3. Category
    buffer.writeln('### ${AppLocalizations.of(context)!.category}'); // i18n for '分类'
    buffer.writeln(category ?? '');
    buffer.writeln();
    // 4. Diary content
    buffer.writeln('### ${AppLocalizations.of(context)!.diaryContent}'); // i18n for '日记内容'
    buffer.writeln(content);
    buffer.writeln();
    // 5. Content analysis
    buffer.writeln('### ${AppLocalizations.of(context)!.contentAnalysis}'); // i18n for '内容分析'
    buffer.writeln(analysis);
    buffer.writeln();
    // Separator
    buffer.writeln('---');
    buffer.writeln();
    return buffer.toString();
  }

  /// Parse markdown to chat history, returns List<DiaryEntry>
  /// Each entry contains: title, time, category, q, a
  /// Results are sorted by time in descending order (newest first)
  static List<DiaryEntry> parseDiaryMarkdownToChatHistory(BuildContext context, String content) {
    final lines = content.split('\n');
    final List<Map<String, String>> rawEntries = [];
    Map<String, String> currentItem = {};
    String? currentSection;

    // Helper function to get section type from header text
    String? getSectionType(String headerText) {
      final lower = headerText.toLowerCase();
      // Only match exact section headers, not partial matches
      if (lower == '时间' || lower == 'time') return 'time';
      if (lower == '分类' || lower == 'category') return 'category';
      if (lower == '日记内容' || lower == 'diary content') return 'q';
      if (lower == '内容分析' || lower == 'content analysis') return 'a';
      return null;
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('## ')) {
        // New diary entry title
        if (currentItem.isNotEmpty) {
          rawEntries.add(currentItem);
        }
        currentItem = {'title': trimmed.substring(3)};
        currentSection = null;
      } else if (trimmed.startsWith('### ')) {
        // Section header with ### prefix
        currentSection = getSectionType(trimmed.substring(4));
      } else if (trimmed == '---') {
        // End of diary entry
        if (currentItem.isNotEmpty) {
          rawEntries.add(currentItem);
        }
        currentItem = {};
        currentSection = null;
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        // Check if it's a standalone section header (without ### prefix)
        // Only consider it a section header if it's an exact match and not part of content
        if (currentSection == null || currentItem[currentSection] == null) {
          final sectionType = getSectionType(trimmed);
          if (sectionType != null) {
            currentSection = sectionType;
            continue; // Skip adding this line as content
          }
        }

        // Add content to current section
        if (currentSection != null) {
          if (currentItem[currentSection] != null) {
            currentItem[currentSection] = '${currentItem[currentSection]}\n$trimmed';
          } else {
            currentItem[currentSection] = trimmed;
          }
        }
      }
    }

    if (currentItem.isNotEmpty) {
      rawEntries.add(currentItem);
    }

    // Convert to DiaryEntry objects and sort by time descending
    final entries = rawEntries.map((map) => DiaryEntry.fromMap(map)).toList();
    entries.sort((a, b) {
      final timeA = a.parsedTime;
      final timeB = b.parsedTime;

      // If both have time, compare them (newest first)
      if (timeA != null && timeB != null) {
        return timeB.compareTo(timeA);
      }
      // If only one has time, prioritize the one with time
      if (timeA != null) return -1;
      if (timeB != null) return 1;
      // If neither has time, maintain original order
      return 0;
    });

    print('DEBUG: Parsed ${entries.length} diary entries, sorted by time desc');
    return entries;
  }

  /// Parse diary markdown content to List<DiaryEntry>, sorted by time descending
  /// This is a more intuitive alias for parseDiaryMarkdownToChatHistory
  /// [content] Diary markdown content to parse
  /// Returns List<DiaryEntry> sorted by time in descending order (newest first)
  static List<DiaryEntry> parseDiaryContent(BuildContext context, String content) {
    return parseDiaryMarkdownToChatHistory(context, content);
  }


  /// 提取所有非总结的日记条目，格式化为：时间，日记内容\n时间，日记内容\n...
 static String extractPlainDiaryEntries(BuildContext context, String content) {
    final entries = DiaryDao.parseDiaryContent(context, content);
    // 只保留非总结（category/title都不是日总结）的条目
    final filtered = entries.where((e) => (e.category?.trim() != '日总结' && e.title.trim() != '日总结'));
    // 只保留有时间和内容的条目
    final lines = filtered.where((e) => (e.time?.isNotEmpty == true && e.q?.isNotEmpty == true))
                          .map((e) => '${e.time}, ${e.q!.replaceAll('\n', ' ').replaceAll('#', '')}')
                          .toList();
    return lines.join('\n');
  }

  /// Remove daily summary section from diary content
  /// This is useful when we want to process diary content without existing summaries
  /// Uses parseDiaryContent to parse entries and filters out summary entries by category
  static String removeDailySummarySection(BuildContext context, String content) {
    if (content.isEmpty) return content;

    try {
      // Parse content to diary entries
      final entries = parseDiaryContent(context, content);

      // Filter out entries with category '日总结' or title '日总结'
      final filteredEntries = entries.where((entry) {
        final category = entry.category?.trim().toLowerCase() ?? '';
        final title = entry.title.trim().toLowerCase();
        return category != '日总结' && title != '日总结';
      }).toList();

      // Convert back to markdown
      return diaryContentToMarkdown(context, filteredEntries);
    } catch (e) {
      print('Failed to parse diary content, falling back to regex approach: $e');
      // Fall back to regex-based approach if parsing fails
      final summaryRegex = RegExp(r'## 日总结\n(?:(?!## [^#]).)*?---\n?', multiLine: true, dotAll: true);
      String processedContent = content.replaceAll(summaryRegex, '').trim();
      processedContent = processedContent.replaceAll(RegExp(r'^---\s*\n+', multiLine: true), '').trim();
      processedContent = processedContent.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      return processedContent;
    }
  }

  /// Convert List<DiaryEntry> back to markdown format
  /// [entries] List of diary entries to convert
  /// Returns formatted markdown string
  static String diaryContentToMarkdown(BuildContext context, List<DiaryEntry> entries) {
    if (entries.isEmpty) return '';

    final buffer = StringBuffer();

    for (final entry in entries) {
      // Use formatDiaryContent to ensure consistent formatting
      final entryMarkdown = formatDiaryContent(
        context: context,
        title: entry.title,
        content: entry.q ?? '',
        analysis: entry.a ?? '',
        category: entry.category,
        time: entry.time,
      );
      buffer.write(entryMarkdown);
    }

    return buffer.toString().trim();
  }

  /// Convert List<Map<String, String>> (history) back to markdown format
  /// 便于UI层直接用分块history重组md内容
  static String historyToMarkdown(BuildContext context, List<Map<String, String>> history) {
    final entries = history.map((e) => DiaryEntry.fromMap(e)).toList();
    return diaryContentToMarkdown(context, entries);
  }

  // === 日记文件操作方法 ===

  /// Get diary directory path
  static Future<String> getDiaryDir() async {
    // 使用标准化的日记目录路径
    try {
      final diaryPath = await StorageService.getDiaryDirPath();
      final diaryDir = Directory(diaryPath);
      if (!await diaryDir.exists()) {
        await diaryDir.create(recursive: true);
      }
      return diaryPath;
    } catch (e) {
      // 异常处理，使用基于应用数据目录的日记路径
      final appDataDir = await AppConfigService.getAppDataDir();
      final standardDiaryDir = Directory('${appDataDir.path}/data/diary');
      if (!await standardDiaryDir.exists()) {
        await standardDiaryDir.create(recursive: true);
      }
      return standardDiaryDir.path;
    }
  }

  /// Save diary content, automatically update the updated field in frontmatter
  static Future<File> saveDiaryMarkdown(String content, {BuildContext? context, String? fileName}) async {
    try {
      print('=== DiaryDao.saveDiaryMarkdown ===');
      final diaryDir = await getDiaryDir();
      print('日记目录: $diaryDir');

      File file;
      if (fileName != null && fileName.isNotEmpty) {
        file = File('$diaryDir/$fileName');
        print('使用指定文件名: $fileName');
      } else {
        // 默认用未命名+时间戳
        final now = DateTime.now();
        final nowStr = now.toIso8601String().substring(0, 19).replaceAll('T', 'T');
        final generatedFileName = '${nowStr.replaceAll(RegExp(r"[\-:T]"), "")}.md';
        file = File('$diaryDir/$generatedFileName');
        print('生成文件名: $generatedFileName');
      }

      print('最终文件路径: ${file.path}');
      print('保存内容长度: ${content.length} 字符');

      final now = DateTime.now();
      final newContent = FrontmatterService.upsert(content, updated: now);
      print('添加frontmatter后内容长度: ${newContent.length} 字符');

      await file.writeAsString(newContent);
      print('文件写入成功');
      return file;
    } catch (e) {
      print('保存失败，错误: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存日记失败: \n${e.toString()}')));
      }
      rethrow;
    }
  }

  /// List all diary files
  static Future<List<FileSystemEntity>> listDiaries() async {
    final diaryDir = await getDiaryDir();
    return Directory(diaryDir).listSync().where((f) => f.path.endsWith('.md')).toList();
  }

  /// Read diary markdown content from file
  static Future<String> readDiaryMarkdown(File file) async {
    return await file.readAsString();
  }

  /// Get all diary filenames (without path), sorted by creation time desc (filenames contain timestamps)
  static Future<List<String>> listDiaryFiles() async {
    final diaryDir = await getDiaryDir();
    final files = Directory(diaryDir).listSync().where((f) => f.path.endsWith('.md')).toList();
    files.sort((a, b) => b.uri.pathSegments.last.compareTo(a.uri.pathSegments.last));
    return files.map((f) => f.uri.pathSegments.last).toList();
  }

  /// Delete the specified diary file
  static Future<void> deleteDiaryFile(String fileName) async {
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Create empty diary file, write frontmatter (created/updated)
  static Future<void> createDiaryFile(String fileName) async {
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');
    if (!await file.exists()) {
      final now = DateTime.now();
      final frontmatter = '${FrontmatterService.generate(created: now, updated: now)}\n';
      await file.writeAsString(frontmatter);
    } else {
      // 如果文件已存在但内容为空或无frontmatter，也补充frontmatter
      final content = await file.readAsString();
      if (!content.trim().startsWith('---')) {
        final now = DateTime.now();
        final frontmatter = '${FrontmatterService.generate(created: now, updated: now)}\n';
        await file.writeAsString(frontmatter + content);
      }
    }
  }

  /// Append content to today's diary file
  static Future<void> appendToDailyDiary(String contentToAppend) async {
    final now = DateTime.now();
    final fileName = getDiaryFileName();
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');

    if (!await file.exists()) {
      // 如果文件不存在，创建并写入初始内容
      final initialContent =
          '# ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 日记\n\n$contentToAppend';
      await saveDiaryMarkdown(initialContent, fileName: fileName);
    } else {
      // 如果文件存在，追加内容（不添加额外的分割线，因为formatDiaryContent已经包含了）
      final currentContent = await file.readAsString();
      final newContent = '$currentContent$contentToAppend';
      await saveDiaryMarkdown(newContent, fileName: fileName);
    }
  }

  /// 获取指定日期的日记文件名，不指定则为当天
  static String getDiaryFileName([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.md';
  }
}
