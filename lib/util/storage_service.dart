import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../config/config_service.dart';

class StorageService {
  /// 所有日记都存储在标准的 data/diary 目录下
  static Future<String> getUserDiaryDir() async {
    try {
      final standardDiaryDir = await getDiaryDirPath();
      // 确保目录存在
      final diaryDirObj = Directory(standardDiaryDir);
      if (!await diaryDirObj.exists()) {
        await diaryDirObj.create(recursive: true);
      }
      print('获取标准日记目录: $standardDiaryDir');
      return standardDiaryDir;
    } catch (e) {
      print('获取日记目录失败: $e');
      // 在出错的情况下，仍然尝试返回一个可用的路径
      final appDataDir = await AppConfigService.getAppDataDir();
      return '${appDataDir.path}/data/diary';
    }
  }

  /// 获取工作目录（优先读取 workDir 字段，只要有就直接用）
  static Future<String?> getWorkDir() async {
    try {
      // 1. 先读取默认目录下的配置文件，获取 workDir 字段
      final appDocDir = await getApplicationDocumentsDirectory();
      // 修复：直接从默认目录读取，避免循环依赖
      final defaultConfigFile = File(path.join(appDocDir.path, 'config', kLummaConfigFileName));
      String? configuredWorkDir;

      if (await defaultConfigFile.exists()) {
        final content = await defaultConfigFile.readAsString();
        if (content.isNotEmpty) {
          try {
            final map = jsonDecode(content);
            if (map is Map && map['sync'] is Map) {
              final syncMap = map['sync'] as Map;
              // 检查两种可能的字段名
              if (syncMap['work_dir'] is String) {
                final dir = syncMap['work_dir'] as String;
                if (dir.isNotEmpty) {
                  configuredWorkDir = dir;
                }
              } else if (syncMap['workDir'] is String) {
                final dir = syncMap['workDir'] as String;
                if (dir.isNotEmpty) {
                  configuredWorkDir = dir;
                }
              }
            }
          } catch (e) {
            print('解析配置文件失败: $e');
          }
        }
      }

      // 只要 workDir 配置存在，直接返回，不再检查 workDir 下的 config 文件
      if (configuredWorkDir != null && configuredWorkDir.isNotEmpty) {
        return configuredWorkDir;
      }
      // 否则返回默认目录
      return appDocDir.path;
    } catch (e) {
      print('获取工作目录失败: $e');
      return null;
    }
  }

  /// 设置工作目录，并迁移配置文件到新 workDir 下
  static Future<void> setWorkDir(String dirPath) async {
    try {
      // 获取当前工作目录
      final currentWorkDir = await getWorkDir();

      // 1. 先在默认位置更新 workDir 配置
      final appDocDir = await getApplicationDocumentsDirectory();
      final defaultConfigDir = Directory(path.join(appDocDir.path, 'config'));
      if (!await defaultConfigDir.exists()) {
        await defaultConfigDir.create(recursive: true);
      }
      final defaultConfigFile = File(path.join(defaultConfigDir.path, kLummaConfigFileName));

      // 如果默认配置文件存在，更新其中的 workDir 字段
      if (await defaultConfigFile.exists()) {
        final content = await defaultConfigFile.readAsString();
        if (content.isNotEmpty) {
          try {
            final map = jsonDecode(content);
            if (map is Map) {
              if (map['sync'] == null) {
                map['sync'] = {};
              }
              (map['sync'] as Map)['work_dir'] = dirPath;
              await defaultConfigFile.writeAsString(jsonEncode(map));
              print('更新默认配置文件中的工作目录: $dirPath');
            }
          } catch (e) {
            print('更新默认配置文件失败: $e');
          }
        }
      } else {
        // 如果默认配置文件不存在，创建一个包含 workDir 的配置
        final defaultConfig = {
          'sync': {'work_dir': dirPath},
        };
        await defaultConfigFile.writeAsString(jsonEncode(defaultConfig));
        print('创建默认配置文件并设置工作目录: $dirPath');
      }

      // 2. 然后迁移所有文件到新的工作目录
      await migrateConfigDir(from: currentWorkDir, to: dirPath);

      // 3. 修复：强制刷新配置缓存，确保后续读取新 workDir
      await AppConfigService.clearCache();

      print('设置工作目录: $dirPath，并迁移配置文件');
    } catch (e) {
      print('设置工作目录失败: $e');
    }
  }

  /// 清除工作目录
  static Future<void> clearWorkDir() async {
    try {
      await AppConfigService.update((config) {
        config.sync.workDir = '';
      });
      print('清除工作目录');
    } catch (e) {
      print('清除工作目录失败: $e');
    }
  }

  /// 获取同步URI
  static Future<String?> getSyncUri() async {
    try {
      final appConfig = await AppConfigService.load();
      final uri = appConfig.sync.syncUri;
      print('获取同步URI: {uri.isEmpty ? "null" : uri}');
      return uri.isEmpty ? null : uri;
    } catch (e) {
      print('获取同步URI失败: $e');
      return null;
    }
  }

  /// 设置同步URI
  static Future<void> setSyncUri(String uri) async {
    try {
      await AppConfigService.update((config) {
        config.sync.syncUri = uri;
      });
      print('设置同步URI: $uri');
    } catch (e) {
      print('设置同步URI失败: $e');
    }
  }

  /// 清除同步URI
  static Future<void> clearSyncUri() async {
    try {
      await AppConfigService.update((config) {
        config.sync.syncUri = '';
      });
      print('清除同步URI');
    } catch (e) {
      print('清除同步URI失败: $e');
    }
  }


  /// 获取 AppConfig 文件路径（支持自定义 workDir）
  static Future<String> getAppConfigFilePath({String? workDir}) async {
    final appConfigFileName = kLummaConfigFileName;
    if (workDir != null && workDir.isNotEmpty) {
      return path.join(workDir, 'config', appConfigFileName);
    } else {
      // 使用应用文档目录作为默认位置
      final appDocDir = await getApplicationDocumentsDirectory();
      return path.join(appDocDir.path, 'config', appConfigFileName);
    }
  }

  /// 获取 prompt 目录路径（workDir 直接拼接子目录，getWorkDir 已内置默认目录逻辑）
  static Future<String> getPromptDirPath() async {
    final promptSubDir = 'config/prompt';
    final workDir = await getWorkDir();
    final promptPath = path.join(workDir ?? '', promptSubDir);
    // 确保目录存在
    final promptDir = Directory(promptPath);
    if (!await promptDir.exists()) {
      await promptDir.create(recursive: true);
    }
    return promptPath;
  }

  /// 获取日记目录路径（workDir 直接拼接子目录，getWorkDir 已内置默认目录逻辑）
  static Future<String> getDiaryDirPath() async {
    final diarySubDir = 'data/diary';
    final workDir = await getWorkDir();
    return path.join(workDir ?? '', diarySubDir);
  }

  /// 将旧的数据目录结构迁移到新的标准化目录结构
  static Future<void> migrateToStandardDirectories() async {
    try {
      // 获取应用文档目录
      final appDocDir = await getApplicationDocumentsDirectory();
      final oldRootDir = appDocDir.path;

      // 获取应用标准数据目录
      final appDataDir = await AppConfigService.getAppDataDir();
      final newRootDir = appDataDir.path;

      // 修复：如果 oldRootDir == newRootDir，直接返回，避免无意义迁移
      if (oldRootDir == newRootDir) {
        print('无需迁移，源目录与目标目录相同: $oldRootDir');
        return;
      }

      print('开始数据迁移: 从 $oldRootDir 到 $newRootDir');

      // 1. 迁移配置文件
      final oldConfigFile = File('$oldRootDir/$kLummaConfigFileName');
      if (await oldConfigFile.exists()) {
        final newConfigDir = Directory('$newRootDir/config');
        if (!await newConfigDir.exists()) {
          await newConfigDir.create(recursive: true);
        }
        final newConfigFile = File('${newConfigDir.path}/$kLummaConfigFileName');
        if (!await newConfigFile.exists()) {
          await oldConfigFile.copy(newConfigFile.path);
          print('迁移配置文件: ${oldConfigFile.path} -> ${newConfigFile.path}');
        }
      }

      // 2. 迁移日记目录
      // 首先确保标准的日记目录存在
      final newDiaryDir = Directory('$newRootDir/data/diary');
      if (!await newDiaryDir.exists()) {
        await newDiaryDir.create(recursive: true);
      }

      // 2.1 迁移默认位置的日记
      final oldDiaryDir = Directory('$oldRootDir/data/diary');
      if (await oldDiaryDir.exists()) {
        // 复制文件
        await for (final entity in oldDiaryDir.list()) {
          if (entity is File) {
            final newPath = '${newDiaryDir.path}/${path.basename(entity.path)}';
            if (!await File(newPath).exists()) {
              await entity.copy(newPath);
              print('迁移默认日记文件: ${entity.path} -> $newPath');
            }
          }
        }
      }

      // 2.2 尝试从旧配置文件中读取可能的自定义日记目录
      try {
        if (await oldConfigFile.exists()) {
          final content = await oldConfigFile.readAsString();
          final map = jsonDecode(content);
          if (map is Map && map['sync'] is Map && map['sync']['diary_dir'] is String) {
            final customDiaryDir = map['sync']['diary_dir'] as String;
            if (customDiaryDir.isNotEmpty) {
              // 如果存在自定义日记目录，也迁移其中的文件
              final customDir = Directory(customDiaryDir);
              if (await customDir.exists()) {
                print('发现自定义日记目录: $customDiaryDir');
                await for (final entity in customDir.list()) {
                  if (entity is File && entity.path.endsWith('.md')) {
                    final newPath = '${newDiaryDir.path}/${path.basename(entity.path)}';
                    if (!await File(newPath).exists()) {
                      await entity.copy(newPath);
                      print('迁移自定义目录日记文件: ${entity.path} -> $newPath');
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('尝试迁移自定义日记目录时出错: $e');
      }

      // 3. 迁移 prompt 目录
      final oldPromptDir = Directory('$oldRootDir/config/prompt');
      if (await oldPromptDir.exists()) {
        final newPromptDir = Directory('$newRootDir/config/prompt');
        if (!await newPromptDir.exists()) {
          await newPromptDir.create(recursive: true);
        }
        // 复制文件
        await for (final entity in oldPromptDir.list()) {
          if (entity is File) {
            final newPath = '${newPromptDir.path}/${path.basename(entity.path)}';
            if (!await File(newPath).exists()) {
              await entity.copy(newPath);
              print('迁移 prompt 文件: ${entity.path} -> $newPath');
            }
          }
        }
      }

      print('数据迁移完成');
    } catch (e) {
      print('数据迁移失败: $e');
    }
  }

  /// 迁移配置目录（包括 AppConfig 和 prompt 文件，以及日记文件）
  static Future<void> migrateConfigDir({required String? from, required String? to}) async {
    // 1. 迁移 AppConfig
    final appConfigFileName = kLummaConfigFileName;
    String? fromDir = from;
    String? toDir = to;
    if ((fromDir == null || fromDir.isEmpty) && (toDir == null || toDir.isEmpty)) {
      // 都是默认目录，无需迁移
      return;
    }

    // 避免源目录和目标目录相同的情况
    if (fromDir == toDir) {
      print('无需迁移，源目录与目标目录相同: $fromDir');
      return;
    }

    // 获取默认目录
    final appDocDir = await getApplicationDocumentsDirectory();
    final defaultDir = appDocDir.path;

    // 注意: 新的路径结构中，config 文件位于 config/ 子目录中
    final fromPath = (fromDir == null || fromDir.isEmpty)
        ? path.join(defaultDir, 'config', appConfigFileName)
        : path.join(fromDir, 'config', appConfigFileName);
    final toPath = (toDir == null || toDir.isEmpty)
        ? path.join(defaultDir, 'config', appConfigFileName)
        : path.join(toDir, 'config', appConfigFileName);

    try {
      final fromFile = File(fromPath);
      if (await fromFile.exists()) {
        final toFile = File(toPath);
        await toFile.parent.create(recursive: true);
        await fromFile.copy(toPath);
        print('迁移配置文件: $fromPath -> $toPath');

        // 迁移后，更新新位置配置文件中的 workDir 字段
        if (toDir != null && toDir.isNotEmpty) {
          try {
            final content = await toFile.readAsString();
            if (content.isNotEmpty) {
              final map = jsonDecode(content);
              if (map is Map && map['sync'] is Map) {
                (map['sync'] as Map)['work_dir'] = toDir;
                await toFile.writeAsString(jsonEncode(map));
                print('更新新配置文件中的工作目录: $toDir');
              }
            }
          } catch (e) {
            print('更新新配置文件中的工作目录失败: $e');
          }
        }
      }
    } catch (e) {
      print('迁移 AppConfig 文件失败: $e');
    }

    // 2. 迁移 prompt 目录
    final promptSubDir = 'config/prompt';
    final fromPromptDir = (fromDir == null || fromDir.isEmpty)
        ? path.join(defaultDir, promptSubDir)
        : path.join(fromDir, promptSubDir);
    final toPromptDir = (toDir == null || toDir.isEmpty)
        ? path.join(defaultDir, promptSubDir)
        : path.join(toDir, promptSubDir);
    try {
      final fromDirObj = Directory(fromPromptDir);
      if (await fromDirObj.exists()) {
        final toDirObj = Directory(toPromptDir);
        await toDirObj.create(recursive: true);
        await for (var entity in fromDirObj.list()) {
          if (entity is File) {
            final fileName = path.basename(entity.path);
            final targetPath = path.join(toPromptDir, fileName);
            await entity.copy(targetPath);
            print('迁移 prompt 文件: ${entity.path} -> $targetPath');
          }
        }
      }
    } catch (e) {
      print('迁移 prompt 目录失败: $e');
    }

    // 3. 迁移日记目录
    final diarySubDir = 'data/diary';
    final fromDiaryDir = (fromDir == null || fromDir.isEmpty)
        ? path.join(defaultDir, diarySubDir)
        : path.join(fromDir, diarySubDir);
    final toDiaryDir = (toDir == null || toDir.isEmpty)
        ? path.join(defaultDir, diarySubDir)
        : path.join(toDir, diarySubDir);
    try {
      final fromDirObj = Directory(fromDiaryDir);
      if (await fromDirObj.exists()) {
        final toDirObj = Directory(toDiaryDir);
        await toDirObj.create(recursive: true);
        await for (var entity in fromDirObj.list()) {
          if (entity is File && entity.path.endsWith('.md')) {
            final fileName = path.basename(entity.path);
            final targetPath = path.join(toDiaryDir, fileName);
            if (!await File(targetPath).exists()) {
              await entity.copy(targetPath);
              print('迁移日记文件: ${entity.path} -> $targetPath');
            }
          }
        }
      }
    } catch (e) {
      print('迁移日记目录失败: $e');
    }
  }
}
