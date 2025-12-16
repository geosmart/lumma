import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lumma/dao/diary_dao.dart';

/// Diary statistics service for analyzing diary data
class DiaryStatisticsService {
  /// Get character count for each day in the specified date range
  /// Returns a Map<DateTime, int> where DateTime is normalized to midnight
  static Future<Map<DateTime, int>> getCharacterCountByDate({DateTime? startDate, DateTime? endDate}) async {
    final result = <DateTime, int>{};

    try {
      // Get all diary files
      final diaryDir = await DiaryDao.getDiaryDir();
      final files = Directory(diaryDir).listSync().where((f) => f.path.endsWith('.md')).toList();

      for (var file in files) {
        if (file is! File) continue;

        // Parse filename to get date (format: yyyy-MM-dd.md)
        final fileName = file.uri.pathSegments.last;
        final dateMatch = RegExp(r'(\d{4})-(\d{2})-(\d{2})\.md').firstMatch(fileName);

        if (dateMatch == null) continue;

        final year = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final day = int.parse(dateMatch.group(3)!);
        final date = DateTime(year, month, day);

        // Filter by date range if specified
        if (startDate != null && date.isBefore(startDate)) continue;
        if (endDate != null && date.isAfter(endDate)) continue;

        // Read file content and count characters
        final content = await file.readAsString();

        // Remove frontmatter before counting
        String contentWithoutFrontmatter = content;
        final frontmatterRegex = RegExp(r'^---[\s\S]*?---\n', multiLine: true);
        contentWithoutFrontmatter = content.replaceFirst(frontmatterRegex, '');

        // Remove markdown headers (lines starting with #)
        final headerRegex = RegExp(r'^#{1,6}\s+.*$', multiLine: true);
        final contentWithoutHeaders = contentWithoutFrontmatter.replaceAll(headerRegex, '');

        // Count characters (excluding whitespace)
        final charCount = contentWithoutHeaders.replaceAll(RegExp(r'\s+'), '').length;

        result[date] = charCount;
      }
    } catch (e) {
      debugPrint('Error calculating character count by date: $e');
    }

    return result;
  }

  /// Get total character count for all diaries
  static Future<int> getTotalCharacterCount() async {
    final countByDate = await getCharacterCountByDate();
    return countByDate.values.fold<int>(0, (sum, count) => sum + count);
  }

  /// Get total number of diary days
  static Future<int> getTotalDiaryDays() async {
    final countByDate = await getCharacterCountByDate();
    return countByDate.length;
  }

  /// Get average characters per day (only counting days with entries)
  static Future<double> getAverageCharactersPerDay() async {
    final countByDate = await getCharacterCountByDate();
    if (countByDate.isEmpty) return 0.0;

    final total = countByDate.values.fold<int>(0, (sum, count) => sum + count);
    return total / countByDate.length;
  }

  /// Get the date range of all diaries
  static Future<DateTimeRange?> getDateRange() async {
    try {
      final diaryDir = await DiaryDao.getDiaryDir();
      final files = Directory(diaryDir).listSync().where((f) => f.path.endsWith('.md')).toList();

      if (files.isEmpty) return null;

      DateTime? earliest;
      DateTime? latest;

      for (var file in files) {
        final fileName = file.uri.pathSegments.last;
        final dateMatch = RegExp(r'(\d{4})-(\d{2})-(\d{2})\.md').firstMatch(fileName);

        if (dateMatch == null) continue;

        final year = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final day = int.parse(dateMatch.group(3)!);
        final date = DateTime(year, month, day);

        if (earliest == null || date.isBefore(earliest)) {
          earliest = date;
        }
        if (latest == null || date.isAfter(latest)) {
          latest = date;
        }
      }

      if (earliest != null && latest != null) {
        return DateTimeRange(start: earliest, end: latest);
      }
    } catch (e) {
      debugPrint('Error getting date range: $e');
    }

    return null;
  }

  /// Normalize character count to a scale of 0-1 for heatmap visualization
  /// Returns normalized values for easier color mapping
  static Map<DateTime, double> normalizeCharacterCounts(Map<DateTime, int> counts) {
    if (counts.isEmpty) return {};

    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return counts.map((key, value) => MapEntry(key, 0.0));

    return counts.map((key, value) => MapEntry(key, value / maxCount));
  }

  /// Get color intensity for a given character count
  /// Returns a value between 0 and 4 representing intensity levels
  static int getIntensityLevel(int charCount, int maxCount) {
    if (charCount == 0) return 0;
    if (maxCount == 0) return 0;

    final ratio = charCount / maxCount;
    if (ratio >= 0.75) return 4;
    if (ratio >= 0.50) return 3;
    if (ratio >= 0.25) return 2;
    return 1;
  }
}
