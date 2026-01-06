import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:lumma/util/storage_service.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/config/settings_ui_config.dart';
import 'package:lumma/util/storage_permission_handler.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/model/sync_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lumma/generated/l10n/app_localizations.dart';

class SyncConfigService {
  static Future<Map?> loadSyncConfig() async {
    final appConfig = await AppConfigService.load();
    return appConfig.sync.toMap();
  }

  static Future<void> saveSyncConfig(Map syncConfig) async {
    await AppConfigService.update((c) {
      c.sync = SyncConfig.fromMap(syncConfig);
    });
  }
}

class SyncConfigPage extends StatefulWidget {
  const SyncConfigPage({super.key});

  @override
  State<SyncConfigPage> createState() => _SyncConfigPageState();
}

class _SyncConfigPageState extends State<SyncConfigPage> {
  String? _workDir;
  String? _syncUri;
  // 新增 WebDAV 字段
  String? _webdavUrl;
  String? _webdavUsername;
  String? _webdavPassword;
  String? _webdavRemoteDir;
  bool _isLoading = true;
  SyncType _syncType = SyncType.obsidian;
  bool _obscureWebdavUrl = true;
  bool _obscureWebdavUsername = true;
  bool _obscureWebdavPassword = true;

  @override
  void initState() {
    super.initState();
    _loadSyncConfig();
  }

  Future<void> _loadSyncConfig() async {
    setState(() {
      _isLoading = true;
    });
    final workDir = await StorageService.getWorkDir();
    final syncUri = await StorageService.getSyncUri();
    final appConfig = await AppConfigService.load();
    final sync = appConfig.sync;
    setState(() {
      _workDir = workDir;
      _syncUri = syncUri;
      _webdavUrl = sync.webdavUrl;
      _webdavUsername = sync.webdavUsername;
      _webdavPassword = sync.webdavPassword;
      _webdavRemoteDir = sync.webdavRemoteDir;
      _syncType = sync.syncType;
      _isLoading = false;
    });
  }

  Future<void> _saveSyncType(SyncType type) async {
    setState(() {
      _syncType = type;
    });
    await AppConfigService.update((config) {
      config.sync.syncType = type;
    });
  }

  Future<void> _saveWebdavConfig() async {
    await AppConfigService.update((config) {
      config.sync.webdavUrl = _webdavUrl ?? '';
      config.sync.webdavUsername = _webdavUsername ?? '';
      config.sync.webdavPassword = _webdavPassword ?? '';
      config.sync.webdavRemoteDir = _webdavRemoteDir ?? '';
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.webdavConfigSaved)));
    }
  }

  Future<void> _selectWorkDirectory() async {
    // 对于 Android，首先检查权限
    if (Platform.isAndroid) {
      final hasPermission = await StoragePermissionHandler.requestStoragePermission(context);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.storagePermissionRequired),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: AppLocalizations.of(context)!.selectDataWorkDirectory,
    );

    if (directory != null) {
      final oldWorkDir = _workDir;
      await StorageService.setWorkDir(directory);
      // 迁移数据
      await StorageService.migrateConfigDir(from: oldWorkDir, to: directory);
      // 切换工作目录后，重新初始化目录结构
      await AppConfigService.init();
      setState(() {
        _workDir = directory;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.dataWorkDirectorySetSuccess)));
        // 新增弹窗提示
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('提示'),
            content: Text('数据存储目录已更改，应用将退出。请重新打开应用以应用更改。'),
            actions: [
              TextButton(
                onPressed: () {
                  exit(0);
                },
                child: Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _editSyncUri() async {
    final controller = TextEditingController(text: _syncUri ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.enterSyncAddress),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.syncAddress,
            hintText: AppLocalizations.of(context)!.syncAddressPlaceholder,
          ),
          maxLines: null, // 设置为多行输入框
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    if (result != null) {
      await StorageService.setSyncUri(result);
      setState(() {
        _syncUri = result.isEmpty ? null : result;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.syncAddressSetSuccess)));
      }
    }
  }

  Future<void> _clearWorkDirectory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmClear),
        content: Text(AppLocalizations.of(context)!.confirmClearDataWorkDirectory),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final oldWorkDir = _workDir;
      await StorageService.clearWorkDir();
      // 迁移数据到默认目录
      await StorageService.migrateConfigDir(from: oldWorkDir, to: null);
      setState(() {
        _workDir = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.dataWorkDirectoryCleared)));
      }
    }
  }

  Future<void> _clearSyncUri() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmClear),
        content: Text(AppLocalizations.of(context)!.confirmClearSyncAddress),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearSyncUri();
      setState(() {
        _syncUri = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.syncAddressCleared)));
      }
    }
  }

  Future<void> _testWebdavConnection() async {
    final url = _webdavUrl?.trim() ?? '';
    final username = _webdavUsername?.trim() ?? '';
    final password = _webdavPassword ?? '';
    final remoteDirectory = _webdavRemoteDir?.trim() ?? '';
    final localDirectory = _workDir?.trim() ?? '';
    if (url.isEmpty || username.isEmpty || password.isEmpty || remoteDirectory.isEmpty || localDirectory.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseCompleteWebdavConfig)));
      return;
    }
    try {
      // 拼接完整目录URL
      String dirUrl = url;
      if (!dirUrl.endsWith('/')) dirUrl += '/';
      String cleanDir = remoteDirectory.replaceAll(RegExp(r'^/+|/+$'), '');
      String testUrl = '$dirUrl$cleanDir/';
      // 发送 PROPFIND 请求
      final request = http.Request('PROPFIND', Uri.parse(testUrl))
        ..headers.addAll({'Depth': '0', 'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}'});
      final streamed = await request.send();
      if (streamed.statusCode == 207 || streamed.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.webdavConnectionSuccess)));
      } else if (streamed.statusCode == 401) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.authenticationFailed)));
      } else if (streamed.statusCode == 404) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.directoryNotFound)));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.connectionFailed(streamed.statusCode))));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.connectionError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
          // 同步方式选择
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.syncMethod,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.primaryTextColor),
                ),
                RadioListTile<SyncType>(
                  value: SyncType.obsidian,
                  groupValue: _syncType,
                  onChanged: (v) => v != null ? _saveSyncType(v) : null,
                  title: Text(AppLocalizations.of(context)!.obsidianSync),
                ),
                RadioListTile<SyncType>(
                  value: SyncType.webdav,
                  groupValue: _syncType,
                  onChanged: (v) => v != null ? _saveSyncType(v) : null,
                  title: Text(AppLocalizations.of(context)!.webdavSync),
                ),
              ],
            ),
          ),
          // Obsidian 配置
          if (_syncType == SyncType.obsidian) ...[_buildSyncUriCard()],
          // WebDAV 配置
          if (_syncType == SyncType.webdav) ...[_buildWebdavConfigCard()],
          // 其它通用配置
          const SizedBox(height: 20),
          _buildConfigCard(
            icon: Icons.settings,
            title: AppLocalizations.of(context)!.dataWorkDirectory,
            description: AppLocalizations.of(context)!.dataWorkDirectoryDescription,
            value: _workDir,
            onSelect: _selectWorkDirectory,
            onClear: _clearWorkDirectory,
          ),
          const SizedBox(height: 20),
          // 移除日记目录相关设置
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required IconData icon,
    required String title,
    required String description,
    required String? value,
    required VoidCallback onSelect,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: context.primaryTextColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
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
            child: Text(description, style: TextStyle(color: context.secondaryTextColor, fontSize: 14)),
          ),
          if (value != null)
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
                child: Text(value, style: TextStyle(color: context.primaryTextColor, fontSize: 14)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.folder_open),
                  label: Text(AppLocalizations.of(context)!.select),
                ),
                if (value != null)
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear),
                    label: Text(AppLocalizations.of(context)!.clear),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncUriCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.link, color: context.primaryTextColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.syncAddress,
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
              AppLocalizations.of(context)!.syncAddressDescription,
              style: TextStyle(color: context.secondaryTextColor, fontSize: 14),
            ),
          ),
          if (_syncUri != null)
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
                child: Text(_syncUri!, style: TextStyle(color: context.primaryTextColor, fontSize: 14)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _editSyncUri,
                  icon: const Icon(Icons.edit),
                  label: Text(AppLocalizations.of(context)!.setSyncAddress),
                ),
                if (_syncUri != null)
                  TextButton.icon(
                    onPressed: _clearSyncUri,
                    icon: const Icon(Icons.clear),
                    label: Text(AppLocalizations.of(context)!.clear),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebdavConfigCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: context.primaryTextColor, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.webdavConfig,
                style: TextStyle(
                  fontSize: SettingsUiConfig.titleFontSize,
                  fontWeight: SettingsUiConfig.titleFontWeight,
                  color: context.primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.webdavUrl,
              hintText: AppLocalizations.of(context)!.webdavUrlPlaceholder,
              suffixIcon: IconButton(
                icon: Icon(_obscureWebdavUrl ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscureWebdavUrl = !_obscureWebdavUrl;
                  });
                },
              ),
            ),
            controller: TextEditingController(text: _webdavUrl ?? '')
              ..selection = TextSelection.collapsed(offset: (_webdavUrl ?? '').length),
            onChanged: (v) => _webdavUrl = v,
            obscureText: _obscureWebdavUrl,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.username,
              suffixIcon: IconButton(
                icon: Icon(_obscureWebdavUsername ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscureWebdavUsername = !_obscureWebdavUsername;
                  });
                },
              ),
            ),
            controller: TextEditingController(text: _webdavUsername ?? '')
              ..selection = TextSelection.collapsed(offset: (_webdavUsername ?? '').length),
            onChanged: (v) => _webdavUsername = v,
            obscureText: _obscureWebdavUsername,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.password,
              suffixIcon: IconButton(
                icon: Icon(_obscureWebdavPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () {
                  setState(() {
                    _obscureWebdavPassword = !_obscureWebdavPassword;
                  });
                },
              ),
            ),
            obscureText: _obscureWebdavPassword,
            controller: TextEditingController(text: _webdavPassword ?? '')
              ..selection = TextSelection.collapsed(offset: (_webdavPassword ?? '').length),
            onChanged: (v) => _webdavPassword = v,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.remoteDirectory,
              hintText: AppLocalizations.of(context)!.remoteDirectoryPlaceholder,
            ),
            controller: TextEditingController(text: _webdavRemoteDir ?? '')
              ..selection = TextSelection.collapsed(offset: (_webdavRemoteDir ?? '').length),
            onChanged: (v) => _webdavRemoteDir = v,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _saveWebdavConfig,
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.saveConfig),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _testWebdavConnection,
                icon: const Icon(Icons.cloud_done),
                label: Text(AppLocalizations.of(context)!.testConnection),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
