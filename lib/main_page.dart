import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'diary/diary_chat_page.dart';
import 'diary/diary_qa_page.dart';
import 'config/settings_page.dart';
import 'diary/diary_file_list_page.dart';
import 'config/diary_mode_config_service.dart';
import 'config/theme_service.dart';
import 'util/storage_service.dart';
import 'util/sync_service.dart';
import 'model/enums.dart';
import 'package:url_launcher/url_launcher.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  @override
  void initState() {
    super.initState();

    // 应用启动时检查同步配置
    _checkSyncConfig();
  }

  Future<void> _checkSyncConfig() async {
    developer.log('应用启动时检查同步配置', name: 'MainTabPage');
    final isSyncConfigured = await SyncService.isSyncConfigured();
    developer.log('同步配置状态: ${isSyncConfigured ? "已配置" : "未配置"}', name: 'MainTabPage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 背景装饰元素
              Positioned(
                top: 60,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.decorationColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.decorationColor,
                  ),
                ),
              ),

              // 主内容
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 80),

                    // LOGO区域
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: context.primaryButtonGradient,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 应用标题
                    Text(
                      'Lumma',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: context.primaryTextColor,
                        letterSpacing: 2.0,
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black12,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 副标题
                    Text(
                      'AI驱动的问答日记',
                      style: TextStyle(
                        fontSize: 18,
                        color: context.secondaryTextColor,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const Spacer(),

                    // 主操作按钮
                    Container(
                      width: double.infinity,
                      height: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: context.primaryButtonGradient,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () async {
                            final mode = await DiaryModeConfigService.loadDiaryMode();
                            if (mode == DiaryMode.chat) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DiaryChatPage()),
                              );
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DiaryQaPage()),
                              );
                            }
                          },
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  '开始写日记',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 次要操作按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.list_alt,
                            label: '日记列表',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const DiaryFileListPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.sync,
                            label: '数据同步',
                            onTap: () async {
                              // 直接调用主页同步按钮逻辑
                              final syncButtonState = context.findAncestorStateOfType<_SyncButtonState>();
                              syncButtonState?._syncData();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.settings,
                            label: '设置',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsPage()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 次要按钮组件
class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: context.primaryTextColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.primaryTextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 同步按钮组件
class _SyncButton extends StatefulWidget {
  const _SyncButton();

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
  bool _isSyncing = false;

  Future<void> _syncData() async {
    const uri = 'obsidian://adv-uri?vault=mobile&commandid=nutstore-sync%3Astart-sync';
    setState(() {
      _isSyncing = true;
    });
    try {
      if (await canLaunch(uri)) {
        await launch(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开 Obsidian 同步 URI')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSyncing ? null : _syncData,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _isSyncing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.primaryTextColor,
                      ),
                    )
                  : Icon(
                      Icons.sync,
                      color: context.primaryTextColor,
                      size: 18,
                    ),
                const SizedBox(width: 8),
                Text(
                  _isSyncing ? '正在同步...' : '数据同步',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.primaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
