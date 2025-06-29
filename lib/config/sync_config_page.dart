import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../util/storage_service.dart';
import 'theme_service.dart';
import 'settings_ui_config.dart';
import '../util/storage_permission_handler.dart';
import '../config/config_service.dart';
import '../model/sync_config.dart';

class SyncConfigService {
  static Future<Map?> loadSyncConfig() async {
    final appConfig = await AppConfigService.load();
    return appConfig.sync.isNotEmpty ? appConfig.sync.first.toMap() : null;
  }

  static Future<void> saveSyncConfig(Map syncConfig) async {
    await AppConfigService.update((c) {
      // 假设 sync 只存一个配置
      c.sync = [SyncConfig.fromMap(syncConfig)];
    });
  }
}

class SyncConfigPage extends StatefulWidget {
  const SyncConfigPage({super.key});

  @override
  State<SyncConfigPage> createState() => _SyncConfigPageState();
}

class _SyncConfigPageState extends State<SyncConfigPage> {
  String? _obsidianDir;
  String? _backupDir;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectories();
  }

  Future<void> _loadDirectories() async {
    setState(() {
      _isLoading = true;
    });

    final obsidianDir = await StorageService.getObsidianDiaryDir();
    final backupDir = await StorageService.getSystemBackupDir();

    setState(() {
      _obsidianDir = obsidianDir;
      _backupDir = backupDir;
      _isLoading = false;
    });
  }

  Future<void> _selectObsidianDirectory() async {
    // 对于 Android，首先检查权限
    if (Platform.isAndroid) {
      final hasPermission = await StoragePermissionHandler.requestStoragePermission(context);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('需要文件访问权限才能选择目录'),
            duration: Duration(seconds: 3),
          ));
        }
        return;
      }
    }

    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择Obsidian日记目录',
    );

    if (directory != null) {
      await StorageService.setObsidianDiaryDir(directory);
      setState(() {
        _obsidianDir = directory;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Obsidian日记目录设置成功'),
        ));
      }
    }
  }

  Future<void> _selectBackupDirectory() async {
    // 对于 Android，首先检查权限
    if (Platform.isAndroid) {
      final hasPermission = await StoragePermissionHandler.requestStoragePermission(context);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('需要文件访问权限才能选择目录'),
            duration: Duration(seconds: 3),
          ));
        }
        return;
      }
    }

    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择系统备份目录',
    );

    if (directory != null) {
      await StorageService.setSystemBackupDir(directory);
      setState(() {
        _backupDir = directory;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('系统备份目录设置成功'),
        ));
      }
    }
  }

  Future<void> _clearObsidianDirectory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除Obsidian日记目录设置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearObsidianDiaryDir();
      setState(() {
        _obsidianDir = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('已清除Obsidian日记目录设置'),
        ));
      }
    }
  }

  Future<void> _clearBackupDirectory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除系统备份目录设置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearSystemBackupDir();
      setState(() {
        _backupDir = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('已清除系统备份目录设置'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.backgroundGradient,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 页面标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                Icon(
                  Icons.sync,
                  color: context.primaryTextColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '数据同步',
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Obsidian日记目录配置卡片
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_special,
                        color: context.primaryTextColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Obsidian日记目录',
                        style: TextStyle(
                          fontSize: SettingsUiConfig.titleFontSize,
                          fontWeight: SettingsUiConfig.titleFontWeight,
                          color: context.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    '设置Obsidian日记目录路径，用于同步日记内容到Obsidian',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_obsidianDir != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Text(
                        _obsidianDir!,
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectObsidianDirectory,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('选择目录'),
                      ),
                      if (_obsidianDir != null)
                        TextButton.icon(
                          onPressed: _clearObsidianDirectory,
                          icon: const Icon(Icons.clear),
                          label: const Text('清除'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 系统备份目录配置卡片
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.backup,
                        color: context.primaryTextColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '系统备份目录',
                        style: TextStyle(
                          fontSize: SettingsUiConfig.titleFontSize,
                          fontWeight: SettingsUiConfig.titleFontWeight,
                          color: context.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    '设置系统配置备份目录，用于备份应用设置和配置文件',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (_backupDir != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Text(
                        _backupDir!,
                        style: TextStyle(
                          color: context.primaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectBackupDirectory,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('选择目录'),
                      ),
                      if (_backupDir != null)
                        TextButton.icon(
                          onPressed: _clearBackupDirectory,
                          icon: const Icon(Icons.clear),
                          label: const Text('清除'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
