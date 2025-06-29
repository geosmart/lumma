import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

/// 解析 frontmatter 获取 created 字段
Future<DateTime?> getDiaryCreatedTime(String diaryFileName) async {
  try {
    // 优先使用系统配置中的 Obsidian 日记目录
    String? diaryDirPath;
    try {
      final obsidianDir = await StorageService.getObsidianDiaryDir();
      if (obsidianDir != null && obsidianDir.isNotEmpty) {
        diaryDirPath = obsidianDir;
      }
    } catch (_) {}
    if (diaryDirPath == null) {
      final appDir = await getApplicationDocumentsDirectory();
      diaryDirPath = '${appDir.path}/data/diary';
    }
    final file = File('${diaryDirPath}/$diaryFileName');
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    final reg = RegExp(r'^---([\s\S]*?)---', multiLine: true);
    final match = reg.firstMatch(content);
    if (match != null) {
      final lines = match.group(1)!.split('\n');
      for (final l in lines) {
        if (l.trim().startsWith('created:')) {
          final t = l.split(':').sublist(1).join(':').trim();
          return DateTime.tryParse(t);
        }
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}
