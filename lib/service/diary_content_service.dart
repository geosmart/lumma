import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lumma/dao/diary_dao.dart';

/// Diary content service class, handles business logic for diary content
class DiaryContentService {
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

  /// Rebuild markdown content from chat history (List<Map<String, String>>)
  static String rebuildContentFromHistory(BuildContext context, List<Map<String, String>> history) {
    return DiaryDao.historyToMarkdown(context, history);
  }
}
