import 'dart:io';
import 'package:flutter/material.dart';
import 'frontmatter_service.dart';

class MarkdownService {
  // ...existing code...

  /// 覆盖当天的日记内容（不追加，直接覆盖）
  static Future<void> overwriteDailyDiary(String contentToWrite) async {
    final now = DateTime.now();
    final fileName = 'diary_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.md';
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');

    if (!await file.exists()) {
      // 如果文件不存在，创建并写入初始内容
      final initialContent = '# ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 日记\n\n---\n\n$contentToWrite\n\n';
      await saveDiaryMarkdown(initialContent, fileName: fileName);
    } else {
      // 如果文件存在，直接覆盖内容
      await saveDiaryMarkdown(contentToWrite, fileName: fileName);
    }
  }

  // ...existing code...
}
