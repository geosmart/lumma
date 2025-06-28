import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'frontmatter_service.dart';

class MarkdownService {
  static Future<String> getDiaryDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final diaryDir = Directory('${dir.path}/data/diary');
    if (!await diaryDir.exists()) {
      await diaryDir.create(recursive: true);
    }
    return diaryDir.path;
  }

  /// 保存日记内容，自动更新 frontmatter 的 updated 字段
  static Future<File> saveDiaryMarkdown(String content, {BuildContext? context, String? fileName}) async {
    try {
      final diaryDir = await getDiaryDir();
      File file;
      if (fileName != null && fileName.isNotEmpty) {
        file = File('$diaryDir/$fileName');
      } else {
        // 默认用未命名+时间戳
        final now = DateTime.now();
        final nowStr = now.toIso8601String().substring(0,19).replaceAll('T', 'T');
        file = File('$diaryDir/${nowStr.replaceAll(RegExp(r"[\-:T]"), "")}.md');
      }
      final now = DateTime.now();
      final newContent = FrontmatterService.upsert(content, updated: now);
      await file.writeAsString(newContent);
      return file;
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存日记失败: \n${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  static Future<List<FileSystemEntity>> listDiaries() async {
    final diaryDir = await getDiaryDir();
    return Directory(diaryDir).listSync().where((f) => f.path.endsWith('.md')).toList();
  }

  static Future<String> readDiaryMarkdown(File file) async {
    return await file.readAsString();
  }

  /// 获取所有日记文件名（不含路径），按创建时间desc排列（文件名自带时间戳）
  static Future<List<String>> listDiaryFiles() async {
    final diaryDir = await getDiaryDir();
    final files = Directory(diaryDir)
        .listSync()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    files.sort((a, b) => b.uri.pathSegments.last.compareTo(a.uri.pathSegments.last));
    return files.map((f) => f.uri.pathSegments.last).toList();
  }

  /// 删除指定日记文件
  static Future<void> deleteDiaryFile(String fileName) async {
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 新建空日记文件，写入 frontmatter（created/updated）
  static Future<void> createDiaryFile(String fileName) async {
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');
    if (!await file.exists()) {
      final now = DateTime.now();
      final frontmatter = FrontmatterService.generate(created: now, updated: now) + '\n';
      await file.writeAsString(frontmatter);
    } else {
      // 如果文件已存在但内容为空或无frontmatter，也补充frontmatter
      final content = await file.readAsString();
      if (!content.trim().startsWith('---')) {
        final now = DateTime.now();
        final frontmatter = FrontmatterService.generate(created: now, updated: now) + '\n';
        await file.writeAsString(frontmatter + content);
      }
    }
  }

  /// 追加内容到当天的日记文件
  static Future<void> appendToDailyDiary(String contentToAppend) async {
    final now = DateTime.now();
    final fileName = 'diary_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.md';
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');

    if (!await file.exists()) {
      // 如果文件不存在，创建并写入初始内容
      final initialContent = '# ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 日记\n\n---\n\n$contentToAppend\n\n';
      await saveDiaryMarkdown(initialContent, fileName: fileName);
    } else {
      // 如果文件存在，追加内容
      final currentContent = await file.readAsString();
      final newContent = '$currentContent\n---\n\n$contentToAppend\n\n';
      await saveDiaryMarkdown(newContent, fileName: fileName);
    }
  }
}
