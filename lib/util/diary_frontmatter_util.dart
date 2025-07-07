import 'dart:io';
import '../config/config_service.dart';
import 'storage_service.dart';

/// Parse frontmatter to get the created field
Future<DateTime?> getDiaryCreatedTime(String diaryFileName) async {
  try {
    // 使用标准化的日记目录路径
    String diaryDirPath;
    try {
      diaryDirPath = await StorageService.getDiaryDirPath();
    } catch (_) {
      // 异常处理，使用基于应用数据目录的日记路径
      final appDataDir = await AppConfigService.getAppDataDir();
      diaryDirPath = '${appDataDir.path}/data/diary';
    }
    final file = File('$diaryDirPath/$diaryFileName');
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
