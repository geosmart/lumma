import 'dart:io';
import 'dart:convert';
import 'config_service.dart';
import 'package:path/path.dart' as p;

class DiaryModeConfigService {
  static const String _fileName = 'diary_configs.json';

  // 统一调用 ConfigService 的 configDir
  static Future<String> get _configDir async {
    // 这里直接用项目根目录下 config
    return await ConfigService.getProjectConfigDir();
  }

  static Future<File> get _configFile async {
    final path = await _configDir;
    return File(p.join(path, _fileName));
  }

  static Future<String> loadDiaryMode() async {
    final file = await _configFile;
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final map = jsonDecode(content);
        return map['mode'] ?? 'qa';
      }
    }
    return 'qa'; // 默认固定问答
  }

  static Future<void> saveDiaryMode(String mode) async {
    final file = await _configFile;
    await file.writeAsString(jsonEncode({'mode': mode}));
  }
}
