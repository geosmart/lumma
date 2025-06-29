package com.xtool.lumma

import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.xtool.lumma/storage_permission"
    private val STORAGE_PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 设置方法通道以处理权限请求
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "requestStoragePermission") {
                // 处理Android 10及以上版本的存储权限
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    if (!Environment.isExternalStorageManager()) {
                        try {
                            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                            val uri = Uri.fromParts("package", packageName, null)
                            intent.data = uri
                            startActivityForResult(intent, STORAGE_PERMISSION_REQUEST_CODE)
                            result.success(false)
                        } catch (e: Exception) {
                            result.error("PERMISSION_ERROR", "无法请求文件管理权限", e.toString())
                        }
                    } else {
                        result.success(true)
                    }
                } else {
                    // 低于Android 10的版本已通过Manifest处理权限
                    result.success(true)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
