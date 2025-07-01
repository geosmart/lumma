import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../config/config_service.dart';

class StorageService {
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

  /// 获取用户日记目录
  static Future<String?> getUserDiaryDir() async {
    try {
      final appConfig = await AppConfigService.load();
      final dir = appConfig.sync.diaryDir;
      developer.log('获取用户日记目录: ${dir.isEmpty ? "null" : dir}', name: 'StorageService');
      return dir.isEmpty ? null : dir;
    } catch (e) {
      developer.log('获取用户日记目录失败: $e', name: 'StorageService');
      return null;
    }
  }

  /// 保存用户日记目录
  static Future<void> setUserDiaryDir(String path) async {
    try {
      await AppConfigService.update((config) {
        config.sync.diaryDir = path;
      });
      developer.log('设置用户日记目录: $path', name: 'StorageService');
    } catch (e) {
      developer.log('设置用户日记目录失败: $e', name: 'StorageService');
    }
  }

  /// 清除用户日记目录
  static Future<void> clearUserDiaryDir() async {
    try {
      await AppConfigService.update((config) {
        config.sync.diaryDir = '';
      });
      developer.log('清除用户日记目录', name: 'StorageService');
    } catch (e) {
      developer.log('清除用户日记目录失败: $e', name: 'StorageService');
    }
  }

  /// 获取配置文件目录
  static Future<String?> getConfigDir() async {
    try {
      final appConfig = await AppConfigService.load();
      final dir = appConfig.sync.configDir;
      developer.log('获取配置文件目录: ${dir.isEmpty ? "null" : dir}', name: 'StorageService');
      return dir.isEmpty ? null : dir;
    } catch (e) {
      developer.log('获取配置文件目录失败: $e', name: 'StorageService');
      return null;
    }
  }

  /// 设置配置文件目录
  static Future<void> setConfigDir(String path) async {
    try {
      await AppConfigService.update((config) {
        config.sync.configDir = path;
      });
      developer.log('设置配置文件目录: $path', name: 'StorageService');
    } catch (e) {
      developer.log('设置配置文件目录失败: $e', name: 'StorageService');
    }
  }

  /// 清除配置文件目录
  static Future<void> clearConfigDir() async {
    try {
      await AppConfigService.update((config) {
        config.sync.configDir = '';
      });
      developer.log('清除配置文件目录', name: 'StorageService');
    } catch (e) {
      developer.log('清除配置文件目录失败: $e', name: 'StorageService');
    }
  }

  /// 获取同步URI
  static Future<String?> getSyncUri() async {
    try {
      final appConfig = await AppConfigService.load();
      final uri = appConfig.sync.syncUri;
      developer.log('获取同步URI: ${uri.isEmpty ? "null" : uri}', name: 'StorageService');
      return uri.isEmpty ? null : uri;
    } catch (e) {
      developer.log('获取同步URI失败: $e', name: 'StorageService');
      return null;
    }
  }

  /// 设置同步URI
  static Future<void> setSyncUri(String uri) async {
    try {
      await AppConfigService.update((config) {
        config.sync.syncUri = uri;
      });
      developer.log('设置同步URI: $uri', name: 'StorageService');
    } catch (e) {
      developer.log('设置同步URI失败: $e', name: 'StorageService');
    }
  }

  /// 清除同步URI
  static Future<void> clearSyncUri() async {
    try {
      await AppConfigService.update((config) {
        config.sync.syncUri = '';
      });
      developer.log('清除同步URI', name: 'StorageService');
    } catch (e) {
      developer.log('清除同步URI失败: $e', name: 'StorageService');
    }
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
