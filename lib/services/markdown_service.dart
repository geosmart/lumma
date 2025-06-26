import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class MarkdownService {
  static Future<String> getDiaryDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final diaryDir = Directory('${dir.path}/data/diary');
    if (!await diaryDir.exists()) {
      await diaryDir.create(recursive: true);
    }
    return diaryDir.path;
  }

  static Future<File> saveDiaryMarkdown(String content, {BuildContext? context}) async {
    try {
      final diaryDir = await getDiaryDir();
      final now = DateTime.now();
      final file = File('$diaryDir/diary_${now.toIso8601String().replaceAll(':', '').replaceAll('.', '').replaceAll('-', '').substring(0,15)}.md');
      await file.writeAsString(content);
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

  /// 获取所有日记文件名（不含路径）
  static Future<List<String>> listDiaryFiles() async {
    final diaryDir = await getDiaryDir();
    final files = Directory(diaryDir)
        .listSync()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
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

  /// 新建空日记文件
  static Future<void> createDiaryFile(String fileName) async {
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');
    if (!await file.exists()) {
      await file.writeAsString('');
    }
  }
}
