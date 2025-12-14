import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lumma/util/storage_service.dart';
import 'package:lumma/model/enums.dart';
import 'package:lumma/model/sync_config.dart';
import 'package:lumma/service/config_service.dart';
import 'webdav_util.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lumma/view/widgets/sync_progress_dialog.dart';
import 'package:path/path.dart' as path;

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
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('关闭'))],
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

  // WebDAV 同步方法 - 支持进度回调
  static Future<bool> syncWithWebdavWithProgress({
    void Function(int current, int total, String filePath)? onProgress,
    void Function()? onDone,
  }) async {
    try {
      print('开始 WebDAV 同步(进度)');
      final config = await AppConfigService.load();
      final syncConfig = config.sync;
      if (syncConfig.webdavUrl.isEmpty || syncConfig.webdavUsername.isEmpty || syncConfig.webdavPassword.isEmpty) {
        print('WebDAV 配置不完整');
        return false;
      }
      // 获取 WebDAV 本地目录（统一使用 dataWorkDirectory）
      final workDir = await StorageService.getWorkDir();
      // 统计总文件数（只统计需要处理的文件）
      final dir = Directory(workDir ?? '');
      final allEntities = await dir.list(recursive: true, followLinks: false).toList();
      int totalFiles = allEntities.whereType<File>().length;
      // 文件夹只做日志，不计入进度
      // 先同步文件夹（不调用 onProgress，不影响进度条）
      final localDirsList = allEntities.whereType<Directory>().map((entity) {
        return entity.path.substring(dir.path.length).replaceAll('\\', '/');
      }).toList();
      localDirsList.sort((a, b) => a.split('/').length.compareTo(b.split('/').length));
      for (final relativePath in localDirsList) {
        final remotePath =
            (syncConfig.webdavRemoteDir.endsWith('/') ? syncConfig.webdavRemoteDir : '${syncConfig.webdavRemoteDir}/') +
            relativePath.replaceFirst('/', '');
        final decodedRemotePath = Uri.encodeFull(remotePath);
        await WebdavUtil.createDirectory(
          webdavUrl: syncConfig.webdavUrl,
          username: syncConfig.webdavUsername,
          password: syncConfig.webdavPassword,
          remotePath: decodedRemotePath,
        );
      }
      // 再同步文件
      int processedFiles = 0;
      final uploadSuccess = await WebdavUtil.uploadDirectoryIncremental(
        webdavUrl: syncConfig.webdavUrl,
        username: syncConfig.webdavUsername,
        password: syncConfig.webdavPassword,
        remoteDir: syncConfig.webdavRemoteDir.isEmpty ? '/' : syncConfig.webdavRemoteDir,
        localDir: workDir ?? '',
        onProgress: (current, total, filePath) {
          // 只统计文件进度，忽略所有文件夹日志（包括下载部分）
          if (onProgress != null && !filePath.startsWith('[目录]')) {
            processedFiles = current;
            // total 应始终为 totalFiles，避免 uploadDirectoryIncremental 传递的 total 不一致
            onProgress(processedFiles, totalFiles, filePath);
          }
        },
      );
      if (!uploadSuccess) {
        print('增量上传本地工作目录失败');
        if (onDone != null) onDone();
        return false;
      }

      // 获取远端 WebDAV 文件总数
      final remoteTotalFiles = await SyncService.getRemoteWebdavFileCount();

      // 增量下载 WebDAV 内容到本地
      print('开始从 WebDAV 增量下载到本地目录');
      // 下载远程 data/diary 目录到本地 workDir/data/diary
      final localDiaryDir = path.join(workDir ?? '', 'data/diary');
      // remoteDir 强制拼接
      final remoteDiaryDir = syncConfig.webdavRemoteDir.endsWith('/')
          ? syncConfig.webdavRemoteDir + 'data/diary'
          : syncConfig.webdavRemoteDir + '/data/diary';
      final downloadSuccess = await WebdavUtil.downloadDirectory(
        webdavUrl: syncConfig.webdavUrl,
        username: syncConfig.webdavUsername,
        password: syncConfig.webdavPassword,
        remoteDir: remoteDiaryDir,
        localDir: localDiaryDir,
        onProgress: (current, total, filePath) {
          if (onProgress != null) {
            onProgress(current, total, filePath);
          }
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
    final uri = Uri.parse(
      syncConfig.webdavUrl +
          (syncConfig.webdavRemoteDir.isEmpty
              ? '/'
              : syncConfig.webdavRemoteDir.endsWith('/')
              ? syncConfig.webdavRemoteDir
              : '${syncConfig.webdavRemoteDir}/'),
    );
    final auth = base64Encode(utf8.encode('${syncConfig.webdavUsername}:${syncConfig.webdavPassword}'));
    final request = http.Request('PROPFIND', uri)
      ..headers.addAll({'Authorization': 'Basic $auth', 'Content-Type': 'application/xml', 'Depth': '1'})
      ..body =
          '''<?xml version="1.0" encoding="utf-8" ?>\n<D:propfind xmlns:D="DAV:">\n  <D:prop>\n    <D:displayname/>\n    <D:getcontentlength/>\n    <D:getcontenttype/>\n    <D:resourcetype/>\n  </D:prop>\n</D:propfind>''';
    final response = await http.Client().send(request);
    if (response.statusCode != 207) return 0;
    final responseBody = await response.stream.bytesToString();
    // 统计 <D:response> 个数
    final matches = RegExp(r'<D:response>').allMatches(responseBody);
    final count = matches.length;
    return count > 0 ? count - 1 : 0;
  }

  static Future<void> syncDataWithContext(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final syncMode = await SyncService.getSyncMode();
    if (syncMode == SyncMode.obsidian) {
      // Obsidian 同步逻辑
      final syncUri = await SyncService.getSyncUri();
      final url = Uri.parse(syncUri!);
      print('尝试同步数据: $url');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('无法启动同步命令，请检查同步设置或 Obsidian 是否安装。');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.cannotStartSync),
            content: Text(l10n.cannotStartSyncMessage),
            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ok))],
          ),
        );
      }
    } else if (syncMode == SyncMode.webdav) {
      final localCount = await SyncService.getLocalDiaryFileCount();
      final remoteCount = await SyncService.getRemoteWebdavFileCount();
      final total = localCount + remoteCount;
      int current = 0;
      String currentFile = '';
      String currentStage = '';
      List<String> logs = [];
      bool isDone = false;
      bool closed = false;
      bool started = false;
      void addLog(String message) {
        final now = DateTime.now();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        logs.insert(0, '$timeStr $message');
      }

      void closeDialog() {
        closed = true;
      }

      if (!started) {
        started = true;
        addLog(l10n.startSyncTask);
        SyncService.syncWithWebdavWithProgress(
          onProgress: (int c, int t, String file) {
            if (closed) return;
            current = c;
            currentFile = file;
            if (c <= localCount) {
              currentStage = l10n.uploading;
              addLog(l10n.uploadFile(file));
            } else {
              currentStage = l10n.downloading;
              addLog(l10n.downloadFile(file));
            }
          },
          onDone: () {
            isDone = true;
            currentStage = l10n.syncTaskComplete;
            addLog(l10n.syncTaskComplete);
          },
        ).then((result) {
          if (closed) return;
          if (result == false) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.syncFailed),
                content: Text(l10n.syncFailedMessage),
                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ok))],
              ),
            );
          }
        });
      }
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              Future.delayed(const Duration(milliseconds: 100), () {
                if (!closed && ctx.mounted) {
                  setState(() {});
                }
              });
              return SyncProgressDialog(
                current: current,
                total: total,
                currentFile: currentFile,
                currentStage: currentStage,
                logs: logs,
                isDone: isDone,
                onClose: () {
                  closeDialog();
                  // 不再 pop 弹窗，交由 SyncProgressDialog 内部处理
                },
              );
            },
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(title: Text(l10n.syncNotConfigured), content: Text(l10n.syncNotConfiguredMessage)),
      );
    }
  }
}
