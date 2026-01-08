import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/controller/language_controller.dart';
import 'package:lumma/controller/theme_controller.dart';
import 'package:lumma/view/pages/sync_config_page.dart';
import 'package:lumma/view/pages/mcp_config_page.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/config/settings_ui_config.dart';
import 'package:lumma/service/config_service.dart' show AppConfigService;
import 'package:lumma/service/mcp_service.dart';

class SettingsPage extends StatelessWidget {
  final int initialTabIndex;

  const SettingsPage({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.settings,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              Tab(icon: Icon(Icons.sync, size: 20)),
              Tab(icon: Icon(Icons.cloud_upload, size: 20)),
              Tab(icon: Icon(Icons.palette, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SyncConfigPage(),
            _McpConfigPage(),
            _AppearanceSettingsPage(),
          ],
        ),
      ),
    );
  }
}

// Appearance settings page (including theme and language)
class _AppearanceSettingsPage extends StatelessWidget {
  const _AppearanceSettingsPage();

  @override
  Widget build(BuildContext context) {
    // 使用 GetX 控制器
    final languageController = Get.find<LanguageController>();
    final themeController = Get.find<ThemeController>();

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
          // Page title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                Icon(Icons.palette, color: context.primaryTextColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.appearanceSettings,
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Language settings - 使用 Obx 监听状态变化
          Obx(
            () => Container(
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
                        Icon(Icons.language, color: context.primaryTextColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.language,
                          style: TextStyle(
                            fontSize: SettingsUiConfig.titleFontSize,
                            fontWeight: SettingsUiConfig.titleFontWeight,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chinese
                  Container(
                    decoration: BoxDecoration(
                      color: languageController.currentLocale.languageCode == 'zh'
                          ? const Color(0xFFF3E5AB).withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: languageController.currentLocale.languageCode == 'zh'
                          ? Border.all(color: const Color(0xFFD4A574), width: 1.5)
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDE2910),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '中',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.languageChinese,
                        style: TextStyle(
                          fontSize: SettingsUiConfig.subtitleFontSize,
                          fontWeight: languageController.currentLocale.languageCode == 'zh'
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: context.primaryTextColor,
                        ),
                      ),
                      trailing: languageController.currentLocale.languageCode == 'zh'
                          ? const Icon(Icons.check_circle, color: Color(0xFFD4A574), size: 20)
                          : null,
                      onTap: () {
                        languageController.setLanguage(const Locale('zh', 'CN'));
                      },
                    ),
                  ),

                  // English
                  Container(
                    decoration: BoxDecoration(
                      color: languageController.currentLocale.languageCode == 'en'
                          ? const Color(0xFFF3E5AB).withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: languageController.currentLocale.languageCode == 'en'
                          ? Border.all(color: const Color(0xFFD4A574), width: 1.5)
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F4C75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'EN',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.languageEnglish,
                        style: TextStyle(
                          fontSize: SettingsUiConfig.subtitleFontSize,
                          fontWeight: languageController.currentLocale.languageCode == 'en'
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: context.primaryTextColor,
                        ),
                      ),
                      trailing: languageController.currentLocale.languageCode == 'en'
                          ? const Icon(Icons.check_circle, color: Color(0xFFD4A574), size: 20)
                          : null,
                      onTap: () {
                        languageController.setLanguage(const Locale('en', 'US'));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Theme switch card - 使用 Obx 监听状态变化
          Obx(
            () => Container(
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
                        Icon(Icons.palette, color: context.primaryTextColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.theme,
                          style: TextStyle(
                            fontSize: SettingsUiConfig.titleFontSize,
                            fontWeight: SettingsUiConfig.titleFontWeight,
                            color: context.primaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Light theme
                  Container(
                    decoration: BoxDecoration(
                      color: themeController.themeMode == ThemeMode.light
                          ? const Color(0xFFF3E5AB).withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: themeController.themeMode == ThemeMode.light
                          ? Border.all(color: const Color(0xFFD4A574), width: 1.5)
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFfdf7f0), Color(0xFFf0e6d6)]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeController.themeMode == ThemeMode.light
                                ? const Color(0xFFD4A574)
                                : context.borderColor,
                            width: themeController.themeMode == ThemeMode.light ? 3 : 2,
                          ),
                        ),
                        child: const Icon(Icons.wb_sunny, color: Color(0xFF8d6e63), size: 20),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.themeLightMode,
                        style: TextStyle(
                          fontWeight: themeController.themeMode == ThemeMode.light ? FontWeight.w600 : FontWeight.w500,
                          color: context.primaryTextColor,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.themeLightDesc,
                        style: TextStyle(color: context.secondaryTextColor),
                      ),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.light,
                        groupValue: themeController.themeMode,
                        activeColor: const Color(0xFFD4A574),
                        onChanged: (value) {
                          if (value != null) {
                            themeController.setTheme(value);
                          }
                        },
                      ),
                      onTap: () {
                        themeController.setTheme(ThemeMode.light);
                      },
                    ),
                  ),

                  Divider(color: context.borderColor, height: 1),

                  // Dark theme
                  Container(
                    decoration: BoxDecoration(
                      color: themeController.themeMode == ThemeMode.dark
                          ? const Color(0xFF3B4CCA).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: themeController.themeMode == ThemeMode.dark
                          ? Border.all(color: const Color(0xFF9FA8DA), width: 1.5)
                          : null,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)]),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeController.themeMode == ThemeMode.dark
                                ? const Color(0xFF9FA8DA)
                                : context.borderColor,
                            width: themeController.themeMode == ThemeMode.dark ? 3 : 2,
                          ),
                        ),
                        child: const Icon(Icons.nightlight_round, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.themeDarkMode,
                        style: TextStyle(
                          fontWeight: themeController.themeMode == ThemeMode.dark ? FontWeight.w600 : FontWeight.w500,
                          color: context.primaryTextColor,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.themeDarkDesc,
                        style: TextStyle(color: context.secondaryTextColor),
                      ),
                      trailing: Radio<ThemeMode>(
                        value: ThemeMode.dark,
                        groupValue: themeController.themeMode,
                        activeColor: const Color(0xFF9FA8DA),
                        onChanged: (value) {
                          if (value != null) {
                            themeController.setTheme(value);
                          }
                        },
                      ),
                      onTap: () {
                        themeController.setTheme(ThemeMode.dark);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Preview card
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.themePreview,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.primaryTextColor),
                ),
                const SizedBox(height: 16),

                // Simulate homepage style
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: context.backgroundGradient),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset('assets/icon/icon.svg', width: 40, height: 40),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.primaryTextColor),
                        ),
                        Text(
                          AppLocalizations.of(context)!.appSubtitle,
                          style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MCP configuration page
class _McpConfigPage extends StatefulWidget {
  const _McpConfigPage();

  @override
  State<_McpConfigPage> createState() => _McpConfigPageState();
}

class _McpConfigPageState extends State<_McpConfigPage> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _entityNameController = TextEditingController();
  bool _enabled = false;
  bool _isLoading = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _entityNameController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await AppConfigService.load();
      final mcpConfig = config.mcp;
      setState(() {
        _enabled = mcpConfig.enabled;
        _urlController.text = mcpConfig.url;
        _tokenController.text = mcpConfig.token;
        _entityNameController.text = mcpConfig.entityName ?? '';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      await AppConfigService.update((config) {
        config.mcp.enabled = _enabled;
        config.mcp.url = _urlController.text.trim();
        config.mcp.token = _tokenController.text.trim();
        config.mcp.entityName = _entityNameController.text.trim();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.saveSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    if (_urlController.text.trim().isEmpty ||
        _tokenController.text.trim().isEmpty ||
        _entityNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整的配置信息')),
      );
      return;
    }

    setState(() => _isTesting = true);
    try {
      final result = await McpService.testConnection(
        url: _urlController.text.trim(),
        token: _tokenController.text.trim(),
        entityName: _entityNameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isTesting = false);
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
          // Page title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                Icon(Icons.cloud_upload, color: context.primaryTextColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'MCP配置',
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Enable switch
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            child: SwitchListTile(
              title: Text(
                '启用MCP同步',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.primaryTextColor,
                ),
              ),
              subtitle: Text(
                '实时保存日记到MCP服务器',
                style: TextStyle(color: context.secondaryTextColor),
              ),
              value: _enabled,
              onChanged: (value) {
                setState(() => _enabled = value);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Configuration form
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '服务器配置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // URL
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'MCP服务器地址',
                    hintText: 'https://mcp-web-url/mcp/v1/message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Token
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: 'Token',
                    hintText: 'lk_...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // Entity ID
                TextField(
                  controller: _entityNameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    hintText: '例如: 麦冬',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.network_check),
                        label: Text(_isTesting ? '测试中...' : '测试连接'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveConfig,
                        icon: const Icon(Icons.save),
                        label: const Text('保存'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Help text
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor.withOpacity(0.5), width: 1),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: context.secondaryTextColor),
                    const SizedBox(width: 8),
                    Text(
                      '说明',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.primaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '启用后，每次发送日记时会自动同步到MCP服务器。\n'
                  '本地保存不受影响，MCP同步失败不会影响正常使用。',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
