import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';
import 'package:flutter/material.dart';

class PromptService {
  static const String _activePromptFile = 'active_prompt.txt';

  static Future<String> get _promptDir async {
    final userDir = await StorageService.getUserDiaryDir();
    if (userDir != null) {
      final promptDir = Directory('$userDir/prompt');
      if (!await promptDir.exists()) {
        await promptDir.create(recursive: true);
      }
      return promptDir.path;
    }
    final dir = await getApplicationDocumentsDirectory();
    final promptDir = Directory('${dir.path}/config/prompt');
    if (!await promptDir.exists()) {
      await promptDir.create(recursive: true);
    }
    return promptDir.path;
  }

  static Future<String> getPromptDir() async {
    return await _promptDir;
  }

  static Future<List<FileSystemEntity>> listPrompts() async {
    final dir = await _promptDir;
    return Directory(dir).listSync().where((f) => f.path.endsWith('.md')).toList();
  }

  static Future<void> setActivePrompt(String fileName, {BuildContext? context}) async {
    try {
      final dir = await _promptDir;
      final file = File('$dir/$_activePromptFile');
      await file.writeAsString(fileName);
    } catch (e) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存提示词失败: \n${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  static Future<String?> getActivePromptFileName() async {
    final dir = await _promptDir;
    final file = File('$dir/$_activePromptFile');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }

  static Future<String?> getActivePromptContent() async {
    final dir = await _promptDir;
    final name = await getActivePromptFileName();
    if (name == null) return null;
    final file = File('$dir/$name');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return null;
  }
}
