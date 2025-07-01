import 'package:flutter/material.dart';
import '../util/storage_service.dart';

class SyncService {
  static Future<bool> isSyncConfigured() async {
    try {
      final diaryDir = await StorageService.getUserDiaryDir();
      final syncUri = await StorageService.getSyncUri();

      // 至少需要配置日记目录和同步URI之一才算配置完成
      return (diaryDir?.isNotEmpty == true) || (syncUri?.isNotEmpty == true);
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
}
