import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../util/storage_service.dart';
import 'theme_service.dart';
import 'settings_ui_config.dart';
import '../util/storage_permission_handler.dart';
import '../config/config_service.dart';
import '../model/sync_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? _configDir;
  String? _diaryDir;
  String? _syncUri;
  // 新增 WebDAV 字段
  String? _webdavUrl;
  String? _webdavUsername;
  String? _webdavPassword;
  String? _webdavDirectory;
  bool _isLoading = true;
  SyncType _syncType = SyncType.obsidian;
  bool _obscureWebdavUrl = false;

  @override
  void initState() {
    super.initState();
    _loadSyncConfig();
  }

  Future<void> _loadSyncConfig() async {
    setState(() {
      _isLoading = true;
    });
    final configDir = await StorageService.getConfigDir();
    final diaryDir = await StorageService.getUserDiaryDir();
    final syncUri = await StorageService.getSyncUri();
    final appConfig = await AppConfigService.load();
    final sync = appConfig.sync;
    setState(() {
      _configDir = configDir;
      _diaryDir = diaryDir;
      _syncUri = syncUri;
      _webdavUrl = sync.webdavUrl;
      _webdavUsername = sync.webdavUsername;
      _webdavPassword = sync.webdavPassword;
      _webdavDirectory = sync.webdavDirectory;
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
      config.sync.webdavDirectory = _webdavDirectory ?? '';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WebDAV 配置已保存')));
    }
  }

  Future<void> _selectConfigDirectory() async {
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
      dialogTitle: '选择配置文件存储目录',
    );

    if (directory != null) {
      await StorageService.setConfigDir(directory);
      setState(() {
        _configDir = directory;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('配置文件存储目录设置成功'),
        ));
      }
    }
  }

  Future<void> _selectDiaryDirectory() async {
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
      dialogTitle: '选择日记文件存储目录',
    );

    if (directory != null) {
      await StorageService.setUserDiaryDir(directory);
      setState(() {
        _diaryDir = directory;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('日记文件存储目录设置成功'),
        ));
      }
    }
  }

  Future<void> _editSyncUri() async {
    final controller = TextEditingController(text: _syncUri ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置同步地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '同步URI',
            hintText: '请输入同步地址',
          ),
          maxLines: 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('同步地址设置成功'),
        ));
      }
    }
  }

  Future<void> _clearConfigDirectory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除配置文件存储目录设置吗？'),
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
      await StorageService.clearConfigDir();
      setState(() {
        _configDir = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('已清除配置文件存储目录设置'),
        ));
      }
    }
  }

  Future<void> _clearDiaryDirectory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除日记文件存储目录设置吗？'),
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
      await StorageService.clearUserDiaryDir();
      setState(() {
        _diaryDir = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('已清除日记文件存储目录设置'),
        ));
      }
    }
  }

  Future<void> _clearSyncUri() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除同步地址设置吗？'),
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
      await StorageService.clearSyncUri();
      setState(() {
        _syncUri = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('已清除同步地址设置'),
        ));
      }
    }
  }

  Future<void> _testWebdavConnection() async {
    final url = _webdavUrl?.trim() ?? '';
    final username = _webdavUsername?.trim() ?? '';
    final password = _webdavPassword ?? '';
    final directory = _webdavDirectory?.trim() ?? '';
    if (url.isEmpty || username.isEmpty || password.isEmpty || directory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请填写完整的 WebDAV 配置信息')));
      return;
    }
    try {
      // 拼接完整目录URL
      String dirUrl = url;
      if (!dirUrl.endsWith('/')) dirUrl += '/';
      String cleanDir = directory.replaceAll(RegExp(r'^/+|/+$'), '');
      String testUrl = dirUrl + cleanDir + '/';
      // 发送 PROPFIND 请求
      final request = http.Request('PROPFIND', Uri.parse(testUrl))
        ..headers.addAll({
          'Depth': '0',
          'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
        });
      final streamed = await request.send();
      if (streamed.statusCode == 207 || streamed.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WebDAV 连接成功，目录存在！')));
      } else if (streamed.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('认证失败，请检查用户名和密码')));
      } else if (streamed.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('目录不存在')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接失败，状态码: ${streamed.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接异常: $e')));
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
          // 同步方式选择
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('同步方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.primaryTextColor)),
                RadioListTile<SyncType>(
                  value: SyncType.obsidian,
                  groupValue: _syncType,
                  onChanged: (v) => v != null ? _saveSyncType(v) : null,
                  title: const Text('Obsidian 同步（基于URI唤起Obsidian插件进行同步）'),
                ),
                RadioListTile<SyncType>(
                  value: SyncType.webdav,
                  groupValue: _syncType,
                  onChanged: (v) => v != null ? _saveSyncType(v) : null,
                  title: const Text('WebDAV 同步（同步到远程 WebDAV 服务器）'),
                ),
              ],
            ),
          ),
          // Obsidian 配置
          if (_syncType == SyncType.obsidian) ...[
            _buildSyncUriCard(),
          ],
          // WebDAV 配置
          if (_syncType == SyncType.webdav) ...[
            _buildWebdavConfigCard(),
          ],
          // 其它通用配置
          const SizedBox(height: 20),
          _buildConfigCard(
            icon: Icons.settings,
            title: '配置文件存储目录',
            description: '设置应用配置文件的存储目录',
            value: _configDir,
            onSelect: _selectConfigDirectory,
            onClear: _clearConfigDirectory,
          ),
          const SizedBox(height: 20),
          _buildConfigCard(
            icon: Icons.book,
            title: '日记文件存储目录',
            description: '设置日记文件的存储目录',
            value: _diaryDir,
            onSelect: _selectDiaryDirectory,
            onClear: _clearDiaryDirectory,
          ),
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
                  icon,
                  color: context.primaryTextColor,
                  size: 24,
                ),
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
            child: Text(
              description,
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 14,
              ),
            ),
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
                child: Text(
                  value,
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
                  onPressed: onSelect,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('选择目录'),
                ),
                if (value != null)
                  TextButton.icon(
                    onPressed: onClear,
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
    );
  }

  Widget _buildSyncUriCard() {
    return Container(
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
                  Icons.link,
                  color: context.primaryTextColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '同步地址',
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
              '设置Obsidian同步的指令对应的AdvanceUri',
              style: TextStyle(
                color: context.secondaryTextColor,
                fontSize: 14,
              ),
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
                child: Text(
                  _syncUri!,
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
                  onPressed: _editSyncUri,
                  icon: const Icon(Icons.edit),
                  label: const Text('设置地址'),
                ),
                if (_syncUri != null)
                  TextButton.icon(
                    onPressed: _clearSyncUri,
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
    );
  }

  Widget _buildWebdavConfigCard() {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud, color: context.primaryTextColor, size: 24),
              const SizedBox(width: 12),
              Text('WebDAV 配置',
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'WebDAV 地址',
              hintText: 'https://your-webdav-server.com',
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
            decoration: const InputDecoration(
              labelText: '用户名',
            ),
            controller: TextEditingController(text: _webdavUsername ?? '')
              ..selection = TextSelection.collapsed(offset: (_webdavUsername ?? '').length),
            onChanged: (v) => _webdavUsername = v,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: '密码',
            ),
            obscureText: true,
            controller: TextEditingController(text: _webdavPassword ?? '')
              ..selection = TextSelection.collapsed(offset: (_webdavPassword ?? '').length),
            onChanged: (v) => _webdavPassword = v,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: '同步目录',
              hintText: '/remote/path/',
            ),
            controller: TextEditingController(text: _webdavDirectory ?? '')
              ..selection = TextSelection.collapsed(offset: (_webdavDirectory ?? '').length),
            onChanged: (v) => _webdavDirectory = v,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _saveWebdavConfig,
                icon: const Icon(Icons.save),
                label: const Text('保存 WebDAV 配置'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _testWebdavConnection,
                icon: const Icon(Icons.cloud_done),
                label: const Text('测试 WebDAV 连接'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
