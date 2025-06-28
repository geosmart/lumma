import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class PromptService {
  static const List<String> promptTypes = [
    'qa', 'correction', 'summary', 'markdown'
  ];

  static Future<String> get _promptDir async {
    final dir = await getApplicationDocumentsDirectory();
    final promptDir = Directory(p.join(dir.path, 'config', 'prompt'));
    if (!await promptDir.exists()) {
      await promptDir.create(recursive: true);
    }
    return promptDir.path;
  }

  static Future<String> getPromptDir() async {
    return await _promptDir;
  }

  /// 获取所有 prompt 文件（可选按类型过滤）
  static Future<List<FileSystemEntity>> listPrompts({String? type}) async {
    final dir = await _promptDir;
    final files = Directory(dir)
        .listSync()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    if (type == null) return files;
    // 修正：异步过滤
    List<FileSystemEntity> filtered = [];
    for (final f in files) {
      final fm = await getPromptFrontmatter(File(f.path));
      if (fm['type'] == type) filtered.add(f);
    }
    return filtered;
  }

  /// 读取 prompt 文件内容
  static Future<String> readPromptContent(String fileName) async {
    final dir = await _promptDir;
    final file = File('$dir/$fileName');
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw Exception('Prompt file not found');
  }

  /// 保存 prompt 文件（自动写入/更新 frontmatter）
  static Future<void> savePrompt({
    required String fileName,
    required String content,
    required String type,
    String? oldFileName,
  }) async {
    final dir = await _promptDir;
    final file = File('$dir/$fileName');
    final now = DateTime.now().toIso8601String();
    Map<String, dynamic> frontmatter = {
      'type': type,
      'updated': now,
    };
    if (await file.exists()) {
      final oldFront = await getPromptFrontmatter(file);
      frontmatter['created'] = oldFront['created'] ?? now;
    } else {
      frontmatter['created'] = now;
    }
    final fmStr = _frontmatterToString(frontmatter);
    final body = _stripFrontmatter(content);
    await file.writeAsString('$fmStr\n$body');
    // 如果重命名
    if (oldFileName != null && oldFileName != fileName) {
      final oldFile = File('$dir/$oldFileName');
      if (await oldFile.exists()) await oldFile.delete();
    }
  }

  /// 删除 prompt 文件
  static Future<void> deletePrompt(String fileName) async {
    final dir = await _promptDir;
    final file = File('$dir/$fileName');
    if (await file.exists()) await file.delete();
  }

  /// 读取 frontmatter
  static Future<Map<String, dynamic>> getPromptFrontmatter(File file) async {
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    final reg = RegExp(r'^---([\s\S]*?)---');
    final match = reg.firstMatch(content);
    if (match != null) {
      final yamlStr = match.group(1)!;
      final doc = loadYaml(yamlStr);
      return Map<String, dynamic>.from(doc);
    }
    return {};
  }

  /// frontmatter 转字符串
  static String _frontmatterToString(Map<String, dynamic> fm) {
    final buf = StringBuffer('---\n');
    fm.forEach((k, v) => buf.writeln('$k: $v'));
    buf.write('---');
    return buf.toString();
  }

  /// 去除 frontmatter
  static String _stripFrontmatter(String content) {
    final reg = RegExp(r'^---([\s\S]*?)---\n?');
    return content.replaceFirst(reg, '').trimLeft();
  }

  /// 获取指定类型的激活 prompt 文件（frontmatter active=true）
  static Future<File?> getActivePromptFile(String type) async {
    final prompts = await listPrompts(type: type);
    for (final f in prompts) {
      final fm = await getPromptFrontmatter(File(f.path));
      if (fm['active'] == true || fm['active'] == 'true') return File(f.path);
    }
    return null;
  }

  /// 获取指定类型的激活 prompt 内容
  static Future<String?> getActivePromptContent(String type) async {
    final file = await getActivePromptFile(type);
    if (file == null) return null;
    final content = await file.readAsString();
    return _stripFrontmatter(content);
  }

  /// 设置指定类型的激活 prompt（将所有同类active=false，目标active=true）
  static Future<void> setActivePrompt(String type, String fileName, {BuildContext? context}) async {
    final prompts = await listPrompts(type: type);
    for (final f in prompts) {
      final file = File(f.path);
      final fm = await getPromptFrontmatter(file);
      final content = await file.readAsString();
      final body = _stripFrontmatter(content);
      final isTarget = p.basename(f.path) == fileName;
      final newFm = Map<String, dynamic>.from(fm);
      newFm['active'] = isTarget;
      final fmStr = _frontmatterToString(newFm);
      await file.writeAsString('$fmStr\n$body');
    }
  }
}
