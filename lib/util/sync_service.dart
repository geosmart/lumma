import 'package:flutter/material.dart';
import 'dart:io';
import '../util/storage_service.dart';
import '../model/enums.dart';
import '../model/sync_config.dart';
import '../config/config_service.dart';
import 'webdav_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SyncService {
  static Future<bool> isSyncConfigured() async {
    try {
      final diaryDir = await StorageService.getUserDiaryDir();
      final syncUri = await StorageService.getSyncUri();

      // 至少需要配置日记目录和同步URI之一才算配置完成
      return (diaryDir.isNotEmpty == true) || (syncUri?.isNotEmpty == true);
    } catch (e) {
      return false;
    }
  }

  static Future<String> diagnoseDirectoryAccess(String dir) async {
    // TODO: 实现目录访问诊断逻辑
    return 'OK';
  }

  static Future<dynamic> syncData(BuildContext context) async {
    // TODO: 实现同步逻辑
    return '同步完成';
  }

  static Future<void> showSyncResultDialog(BuildContext context, dynamic result) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('同步结果'),
        content: Text(result.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  // 获取同步 URI，从配置中读取
  static Future<String?> getSyncUri() async {
    return await StorageService.getSyncUri();
  }

  // 获取同步模式
  static Future<SyncMode> getSyncMode() async {
    final config = await AppConfigService.load();
    if (config.sync.syncType == SyncType.webdav) {
      return SyncMode.webdav;
    } else {
      return SyncMode.obsidian;
    }
  }

  // WebDAV 同步方法 - 覆盖配置目录模式
  static Future<bool> syncWithWebdav() async {
    try {
      print('开始 WebDAV 同步');

      // 获取同步配置
      final config = await AppConfigService.load();
      final syncConfig = config.sync;

      // 检查 WebDAV 配置是否完整
      if (syncConfig.webdavUrl.isEmpty ||
          syncConfig.webdavUsername.isEmpty ||
          syncConfig.webdavPassword.isEmpty) {
        print('WebDAV 配置不完整');
        return false;
      }

      // 获取 WebDAV 本地目录
      final webdavLocalDir = syncConfig.webdavLocalDir;
      if (webdavLocalDir.isEmpty) {
        print('WebDAV 本地目录未设置');
        return false;
      }

      // 检查 WebDAV 本地目录的父目录是否存在，如果不存在则创建
      final localDir = Directory(webdavLocalDir);
      if (!await localDir.parent.exists()) {
        try {
          await localDir.parent.create(recursive: true);
        } catch (e) {
          print('创建 WebDAV 本地目录的父目录失败: $e');
          return false;
        }
      }

      // 增量上传本地日记目录到 WebDAV
      print('开始增量上传本地日记目录到 WebDAV');
      final uploadSuccess = await WebdavUtil.uploadDirectoryIncremental(
        webdavUrl: syncConfig.webdavUrl,
        username: syncConfig.webdavUsername,
        password: syncConfig.webdavPassword,
        remoteDir: syncConfig.webdavRemoteDir.isEmpty ? '/' : syncConfig.webdavRemoteDir,
        localDir: await StorageService.getDiaryDirPath(),
      );

      if (!uploadSuccess) {
        print('增量上传本地日记目录失败');
        return false;
      }

      // 增量下载 WebDAV 内容到本地
      print('开始从 WebDAV 增量下载到本地目录');
      final downloadSuccess = await WebdavUtil.downloadDirectoryIncremental(
        webdavUrl: syncConfig.webdavUrl,
        username: syncConfig.webdavUsername,
        password: syncConfig.webdavPassword,
        remoteDir: syncConfig.webdavRemoteDir.isEmpty ? '/' : syncConfig.webdavRemoteDir,
        localDir: webdavLocalDir,
      );

      if (downloadSuccess) {
        print('WebDAV 同步成功');
        return true;
      } else {
        print('WebDAV 下载失败');
        return false;
      }
    } catch (e, stackTrace) {
      print('WebDAV 同步异常: $e\n$stackTrace');
      return false;
    }
  }

  // WebDAV 同步方法 - 支持进度回调
  static Future<bool> syncWithWebdavWithProgress({
    void Function(int current, int total, String filePath)? onProgress,
    void Function()? onDone,
  }) async {
    try {
      print('开始 WebDAV 同步(进度)');
      final config = await AppConfigService.load();
      final syncConfig = config.sync;
      if (syncConfig.webdavUrl.isEmpty ||
          syncConfig.webdavUsername.isEmpty ||
          syncConfig.webdavPassword.isEmpty) {
        print('WebDAV 配置不完整');
        return false;
      }
      final webdavLocalDir = syncConfig.webdavLocalDir;
      if (webdavLocalDir.isEmpty) {
        print('WebDAV 本地目录未设置');
        return false;
      }
      final localDir = Directory(webdavLocalDir);
      if (!await localDir.parent.exists()) {
        try {
          await localDir.parent.create(recursive: true);
        } catch (e) {
          print('创建 WebDAV 本地目录的父目录失败: $e');
          return false;
        }
      }

      // 统计总文件数（增量同步只计算实际需要处理的文件）
      int totalFiles = 0;
      int processedFiles = 0;

      // 增量上传本地日记目录到 WebDAV
      print('开始增量上传本地日记目录到 WebDAV');
      final uploadSuccess = await WebdavUtil.uploadDirectoryIncremental(
        webdavUrl: syncConfig.webdavUrl,
        username: syncConfig.webdavUsername,
        password: syncConfig.webdavPassword,
        remoteDir: syncConfig.webdavRemoteDir.isEmpty ? '/' : syncConfig.webdavRemoteDir,
        localDir: await StorageService.getDiaryDirPath(),
        onProgress: (current, total, filePath) {
          totalFiles = total; // 更新总数
          processedFiles = current;
          if (onProgress != null) onProgress(processedFiles, totalFiles, filePath);
        },
      );
      if (!uploadSuccess) {
        print('增量上传本地日记目录失败');
        if (onDone != null) onDone();
        return false;
      }

      // 增量下载 WebDAV 内容到本地
      print('开始从 WebDAV 增量下载到本地目录');
      final downloadSuccess = await WebdavUtil.downloadDirectoryIncremental(
        webdavUrl: syncConfig.webdavUrl,
        username: syncConfig.webdavUsername,
        password: syncConfig.webdavPassword,
        remoteDir: syncConfig.webdavRemoteDir.isEmpty ? '/' : syncConfig.webdavRemoteDir,
        localDir: webdavLocalDir,
        onProgress: (current, total, filePath) {
          // 下载进度：上传完成数 + 当前下载数
          final uploadedCount = processedFiles; // 之前上传的文件数
          processedFiles = uploadedCount + current;
          totalFiles = uploadedCount + total; // 更新总数（上传数 + 下载数）
          if (onProgress != null) onProgress(processedFiles, totalFiles, filePath);
        },
      );
      if (onDone != null) onDone();
      if (downloadSuccess) {
        print('WebDAV 同步成功');
        return true;
      } else {
        print('WebDAV 下载失败');
        return false;
      }
    } catch (e, stackTrace) {
      print('WebDAV 同步异常: $e\n$stackTrace');
      if (onDone != null) onDone();
      return false;
    }
  }

  static Future<int> getLocalDiaryFileCount() async {
    final diaryDir = await StorageService.getDiaryDirPath();
    final dir = Directory(diaryDir);
    if (!await dir.exists()) return 0;
    final allEntities = await dir.list(recursive: true, followLinks: false).toList();
    final files = allEntities.whereType<File>().toList();
    return files.length;
  }

  static Future<int> getRemoteWebdavFileCount() async {
    final config = await AppConfigService.load();
    final syncConfig = config.sync;
    final uri = Uri.parse(syncConfig.webdavUrl + (syncConfig.webdavRemoteDir.isEmpty ? '/' : syncConfig.webdavRemoteDir.endsWith('/') ? syncConfig.webdavRemoteDir : '${syncConfig.webdavRemoteDir}/'));
    final auth = base64Encode(utf8.encode('${syncConfig.webdavUsername}:${syncConfig.webdavPassword}'));
    final request = http.Request('PROPFIND', uri)
      ..headers.addAll({
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/xml',
        'Depth': '1',
      })
      ..body = '''<?xml version="1.0" encoding="utf-8" ?>\n<D:propfind xmlns:D="DAV:">\n  <D:prop>\n    <D:displayname/>\n    <D:getcontentlength/>\n    <D:getcontenttype/>\n    <D:resourcetype/>\n  </D:prop>\n</D:propfind>''';
    final response = await http.Client().send(request);
    if (response.statusCode != 207) return 0;
    final responseBody = await response.stream.bytesToString();
    // 统计 <D:response> 个数
    final matches = RegExp(r'<D:response>').allMatches(responseBody);
    final count = matches.length;
    return count > 0 ? count - 1 : 0;
  }
}
