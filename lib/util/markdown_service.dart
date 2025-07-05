import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'frontmatter_service.dart';
import 'storage_service.dart';
import '../config/config_service.dart';

class MarkdownService {
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

  /// 追加内容到当天的日记文件
  static Future<void> appendToDailyDiary(String contentToAppend) async {
    final now = DateTime.now();
    final fileName = getDiaryFileName();
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');

    if (!await file.exists()) {
      // 如果文件不存在，创建并写入初始内容
      final initialContent = '# ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 日记\n\n$contentToAppend';
      await saveDiaryMarkdown(initialContent, fileName: fileName);
    } else {
      // 如果文件存在，追加内容（不添加额外的分割线，因为formatDiaryContent已经包含了）
      final currentContent = await file.readAsString();
      final newContent = '$currentContent$contentToAppend';
      await saveDiaryMarkdown(newContent, fileName: fileName);
    }
  }

  /// 保存或覆盖日总结内容
  static Future<void> saveOrUpdateDailySummary(String summaryContent) async {
    final now = DateTime.now();
    final fileName = getDiaryFileName();
    final diaryDir = await getDiaryDir();
    final file = File('$diaryDir/$fileName');

    if (!await file.exists()) {
      // 如果文件不存在，创建并写入初始内容
      final initialContent = '# ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} 日记\n\n$summaryContent';
      await saveDiaryMarkdown(initialContent, fileName: fileName);
    } else {
      // 如果文件存在，检查是否已有日总结
      final currentContent = await file.readAsString();

      // 查找并删除现有的 ## 日总结 章节（包括其下的所有内容）
      final summaryRegex = RegExp(r'^---\s*\n\n## 日总结\s*\n.*?(?=^---|\Z)', multiLine: true, dotAll: true);

      if (summaryRegex.hasMatch(currentContent)) {
        // 如果已存在日总结，则删除整个章节
        final newContent = currentContent.replaceFirst(summaryRegex, '');
        // 然后追加新的日总结
        final finalContent = '$newContent$summaryContent';
        await saveDiaryMarkdown(finalContent, fileName: fileName);
      } else {
        // 如果不存在日总结，则追加
        final newContent = '$currentContent$summaryContent';
        await saveDiaryMarkdown(newContent, fileName: fileName);
      }
    }
  }

  /// 将所有日记导出为Markdown文件到指定目录
  static Future<int> exportDiaries(String targetDir) async {
    try {
      final diaryDir = await getDiaryDir();
      final files = Directory(diaryDir)
          .listSync()
          .where((f) => f.path.endsWith('.md'))
          .toList();

      int exportCount = 0;
      for (final file in files) {
        if (file is File) {
          final fileName = file.uri.pathSegments.last;
          final targetFile = File('$targetDir/$fileName');

          // 读取源文件内容
          final content = await file.readAsString();

          // 写入目标文件
          await targetFile.writeAsString(content);
          exportCount++;
        }
      }

      return exportCount;  // 返回成功导出的文件数量
    } catch (e) {
      rethrow;
    }
  }  /// 导出指定日记文件为字节数组，用于下载/保存
  static Future<Uint8List> exportDiaryFile(String fileName) async {
    try {
      final diaryDir = await getDiaryDir();
      final file = File('$diaryDir/$fileName');

      if (await file.exists()) {
        // 直接读取文件内容并转换为字节数组
        return await file.readAsBytes();
      } else {
        throw FileSystemException('文件不存在', fileName);
      }
    } catch (e) {
      // 添加更多错误信息以便调试
      if (e is FileSystemException) {
        throw FileSystemException('文件访问错误: ${e.message}', fileName, e.osError);
      }
      rethrow;
    }
  }

  /// 获取指定日期的日记文件名，不指定则为当天
  static String getDiaryFileName([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.md';
  }
}
