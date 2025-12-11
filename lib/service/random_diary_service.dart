import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lumma/dao/diary_dao.dart';

/// Service for fetching random diary entries to display on the home page
class RandomDiaryService {
  static final Random _random = Random();

  /// Get a random diary entry from all diary files
  /// Returns null if no entries are available
  static Future<DiaryEntryWithDate?> getRandomDiaryEntry(BuildContext context) async {
    try {
      // Get all diary entries
      final allEntries = await getAllDiaryEntries(context);

      if (allEntries.isEmpty) {
        return null;
      }

      // Return a random entry
      final randomIndex = _random.nextInt(allEntries.length);
      return allEntries[randomIndex];
    } catch (e) {
      print('[RandomDiaryService] Error fetching random diary entry: $e');
      return null;
    }
  }

  /// Get all diary entries from all diary files
  static Future<List<DiaryEntryWithDate>> getAllDiaryEntries(BuildContext context) async {
    final List<DiaryEntryWithDate> allEntries = [];

    try {
      final diaryDir = await DiaryDao.getDiaryDir();
      final directory = Directory(diaryDir);

      if (!await directory.exists()) {
        return allEntries;
      }

      // Get all .md files
      final files = directory.listSync()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      // Read each file and parse entries
      for (var file in files) {
        try {
          final fileName = file.uri.pathSegments.last;
          final dateStr = _extractDateFromFileName(fileName);

          final content = await File(file.path).readAsString();
          final entries = DiaryDao.parseDiaryContent(context, content);

          // Add each entry with the file date
          for (var entry in entries) {
            allEntries.add(DiaryEntryWithDate(
              entry: entry,
              dateStr: dateStr,
            ));
          }
        } catch (e) {
          print('[RandomDiaryService] Error parsing file ${file.path}: $e');
          continue;
        }
      }

      // Filter out summary entries and entries without content
      return allEntries.where((e) {
        final isSummary = e.entry.category?.trim() == '日总结' ||
                         e.entry.title.trim() == '日总结';
        final hasContent = (e.entry.q?.isNotEmpty ?? false) ||
                          (e.entry.a?.isNotEmpty ?? false);
        return !isSummary && hasContent;
      }).toList();

    } catch (e) {
      print('[RandomDiaryService] Error getting all diary entries: $e');
      return allEntries;
    }
  }

  /// Extract date string from diary file name
  /// Example: "2024-10-12.md" -> "Oct 12, 2024"
  static String _extractDateFromFileName(String fileName) {
    try {
      // Remove .md extension
      final nameWithoutExt = fileName.replaceAll('.md', '');

      // Parse date (format: yyyy-MM-dd)
      final parts = nameWithoutExt.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);

        final date = DateTime(year, month, day);
        return _formatDate(date);
      }
    } catch (e) {
      print('[RandomDiaryService] Error parsing date from filename: $e');
    }

    return fileName.replaceAll('.md', '');
  }

  /// Format date as "Oct 12, 2024" or "2024年10月12日" based on locale
  static String _formatDate(DateTime date) {
    // For now, return English format. Can be enhanced with localization
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final monthStr = months[date.month - 1];
    return '$monthStr ${date.day}, ${date.year}';
  }
}

/// Wrapper class to store diary entry with its date
class DiaryEntryWithDate {
  final DiaryEntry entry;
  final String dateStr;

  DiaryEntryWithDate({
    required this.entry,
    required this.dateStr,
  });

  /// Get display time (combines date and time)
  String getDisplayTime() {
    if (entry.time != null && entry.time!.isNotEmpty) {
      return '$dateStr • ${entry.time}';
    }
    return dateStr;
  }

  /// Get display title
  String getDisplayTitle() {
    return entry.title;
  }

  /// Get display content (prefer q over a)
  String getDisplayContent() {
    if (entry.q != null && entry.q!.isNotEmpty) {
      return entry.q!;
    }
    if (entry.a != null && entry.a!.isNotEmpty) {
      return entry.a!;
    }
    return '';
  }

  /// Truncate content with ellipsis if too long
  String getTruncatedContent({int maxLength = 120}) {
    final content = getDisplayContent();
    if (content.length <= maxLength) {
      return content;
    }
    return '${content.substring(0, maxLength)}...';
  }
}
