import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 处理安卓存储权限相关的工具类
class StoragePermissionHandler {
  static const MethodChannel _channel = MethodChannel('com.xtool.lumma/storage_permission');

  /// 请求存储权限，返回是否已获得权限
  ///
  /// 在 Android 10 (API 29) 及以上，会请求 MANAGE_EXTERNAL_STORAGE 权限
  /// 在低版本 Android 上，会通过 manifest 中声明的权限处理
  /// 在 iOS 和其他平台上，直接返回 true
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final bool hasPermission = await _channel.invokeMethod('requestStoragePermission');

      if (!hasPermission) {
        // 显示一个提示，告诉用户正在请求权限
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请授予应用文件访问权限，以便导出日记文件'), duration: Duration(seconds: 3)));
      }

      return hasPermission;
    } on PlatformException catch (e) {
      debugPrint('获取存储权限失败: ${e.message}');
      return false;
    }
  }
}
