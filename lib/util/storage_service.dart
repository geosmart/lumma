import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class StorageService {
  // Keys for different settings
  static const _key = 'user_diary_dir';
  static const _obsidianDirKey = 'obsidian_diary_dir';
  static const _backupDirKey = 'system_backup_dir';

  // Path to the sync_configs.json file
  static Future<String> get _configFilePath async {
    // Get the application directory path
    final appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, 'config', 'sync_configs.json');
  }

  // Get the configuration file
  static Future<File> get _configFile async {
    final filePath = await _configFilePath;
    final file = File(filePath);
    if (!await file.exists()) {
      // Create the directory if it doesn't exist
      final configDir = Directory(path.dirname(filePath));
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      // Create the file with empty JSON object
      await file.writeAsString('{}');
    }
    return file;
  }

  // Read all configurations from file
  static Future<Map<String, dynamic>> _readConfigs() async {
    try {
      final file = await _configFile;
      final String contents = await file.readAsString();
      if (contents.isEmpty) return {};
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      developer.log('读取配置文件失败: $e', name: 'StorageService');
      // If reading fails, return empty map and try to recreate the file
      try {
        final file = await _configFile;
        await file.writeAsString('{}');
        developer.log('重新创建了空配置文件', name: 'StorageService');
      } catch (e2) {
        developer.log('重新创建配置文件失败: $e2', name: 'StorageService');
      }
      return {};
    }
  }

  // Save all configurations to file
  static Future<void> _saveConfigs(Map<String, dynamic> configs) async {
    try {
      final file = await _configFile;
      final String jsonString = jsonEncode(configs);
      await file.writeAsString(jsonString);
      developer.log('配置已保存到文件: $jsonString', name: 'StorageService', level: 800);
    } catch (e) {
      developer.log('保存配置文件失败: $e', name: 'StorageService', level: 1000);
    }
  }

  // Get value by key
  static Future<String?> _getValue(String key) async {
    final configs = await _readConfigs();
    final value = configs[key] as String?;
    developer.log('_getValue 从配置读取 "$key": ${value ?? "null"}', name: 'StorageService', level: 800);
    return value;
  }

  // Set value by key
  static Future<void> _setValue(String key, String? value) async {
    developer.log('_setValue 保存配置 "$key": ${value ?? "null"}', name: 'StorageService', level: 800);
    final configs = await _readConfigs();
    if (value == null) {
      configs.remove(key);
    } else {
      configs[key] = value;
    }
    await _saveConfigs(configs);
  }

  /// 获取已选目录（无则返回null）
  static Future<String?> getUserDiaryDir() async {
    final value = await _getValue(_key);
    developer.log('获取用户日记目录: ${value ?? "null"}', name: 'StorageService');
    return value;
  }

  /// 保存用户选定目录
  static Future<void> setUserDiaryDir(String path) async {
    await _setValue(_key, path);
  }

  /// 清除用户目录
  static Future<void> clearUserDiaryDir() async {
    await _setValue(_key, null);
  }

  /// 获取Obsidian日记目录
  static Future<String?> getObsidianDiaryDir() async {
    final value = await _getValue(_obsidianDirKey);
    developer.log('获取 Obsidian 日记目录: ${value ?? "null"}', name: 'StorageService');
    return value;
  }

  /// 设置Obsidian日记目录
  static Future<void> setObsidianDiaryDir(String path) async {
    developer.log('设置 Obsidian 日记目录: $path', name: 'StorageService');
    await _setValue(_obsidianDirKey, path);

    // 验证设置是否成功
    final savedValue = await _getValue(_obsidianDirKey);
    developer.log('设置后立即读取 Obsidian 日记目录: ${savedValue ?? "null"}', name: 'StorageService');
  }

  /// 清除Obsidian日记目录
  static Future<void> clearObsidianDiaryDir() async {
    await _setValue(_obsidianDirKey, null);
  }

  /// 获取系统备份目录
  static Future<String?> getSystemBackupDir() async {
    return await _getValue(_backupDirKey);
  }

  /// 设置系统备份目录
  static Future<void> setSystemBackupDir(String path) async {
    await _setValue(_backupDirKey, path);
  }

  /// 清除系统备份目录
  static Future<void> clearSystemBackupDir() async {
    await _setValue(_backupDirKey, null);
  }

  /// 获取配置文件路径（用于调试）
  static Future<String> getConfigFilePath() async {
    return await _configFilePath;
  }

  /// 获取绝对路径的配置文件路径并检查文件存在性
  static Future<Map<String, dynamic>> getAbsoluteConfigFilePath() async {
    final configPath = await _configFilePath;
    final file = File(configPath);
    final exists = await file.exists();

    final result = {
      'path': configPath,
      'exists': exists,
      'directory': path.dirname(configPath),
      'directoryExists': await Directory(path.dirname(configPath)).exists(),
    };

    if (exists) {
      try {
        final content = await file.readAsString();
        result['content'] = content;
        result['size'] = content.length;
        result['isValidJson'] = true;
        result['data'] = jsonDecode(content);
      } catch (e) {
        result['content'] = '';
        result['error'] = e.toString();
        result['isValidJson'] = false;
      }
    }

    developer.log('配置文件绝对路径检查: $result', name: 'StorageService', level: 800);
    return result;
  }

  /// 重置所有配置（用于调试和重置）
  static Future<void> resetAllConfigs() async {
    try {
      final file = await _configFile;
      await file.writeAsString('{}');
      developer.log('重置所有配置成功', name: 'StorageService');
    } catch (e) {
      developer.log('重置所有配置失败: $e', name: 'StorageService');
    }
  }
}
