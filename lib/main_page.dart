import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_svg/flutter_svg.dart';
import 'generated/l10n/app_localizations.dart';
import 'diary/diary_chat_page.dart';
import 'diary/diary_qa_page.dart';
import 'config/settings_page.dart';
import 'diary/diary_file_list_page.dart';
import 'config/diary_mode_config_service.dart';
import 'config/theme_service.dart';
import 'util/sync_service.dart';
import 'model/enums.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/sync_progress_dialog.dart';

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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: context.decorationColor),
                ),
              ),
              Positioned(
                bottom: 100,
                left: -80,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: context.decorationColor),
                ),
              ),

              // 主内容
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 80),

                    // LOGO区域
                    SvgPicture.asset(
                      'assets/icon/icon.svg',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
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
                        shadows: const [Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black12)],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 副标题
                    Text(
                      AppLocalizations.of(context)!.appSubtitle,
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
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () async {
                            final mode = await DiaryModeConfigService.loadDiaryMode();
                            if (mode == DiaryMode.chat) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiaryChatPage()));
                            } else {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiaryQaPage()));
                            }
                          },
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit_note, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)!.startWritingDiary,
                                  style: const TextStyle(
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
                            label: AppLocalizations.of(context)!.diaryList,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiaryFileListPage()));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 用 _SyncButton 替换原来的“数据同步”按钮
                        const Expanded(child: _SyncButton()),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.settings,
                            label: AppLocalizations.of(context)!.settings,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
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

  const _SecondaryButton({required this.icon, required this.label, required this.onTap});

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
              Icon(icon, color: context.primaryTextColor, size: 16),
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
class _SyncButton extends StatelessWidget {
  const _SyncButton();

  Future<void> _syncData(BuildContext context) async {
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
      // 统计本地文件数和远程D:response数-1
      final localCount = await SyncService.getLocalDiaryFileCount();
      final remoteCount = await SyncService.getRemoteWebdavFileCount();
      final total = localCount + remoteCount;

      // 共享状态变量，在弹窗外部定义
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

      // 启动同步任务
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
            addLog(l10n.syncTaskComplete);
          },
        ).then((result) {
          if (closed) return;
          Navigator.of(context, rootNavigator: true).pop();
          if (result == true) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(l10n.syncSuccess),
                content: Text(l10n.syncSuccessMessage),
                actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.ok))],
              ),
            );
          } else {
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
              // 定期刷新UI
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
                  Navigator.of(ctx, rootNavigator: true).pop();
                },
              );
            },
          );
        },
      );
    } else {
      // 未知同步模式
      showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(title: Text(l10n.syncNotConfigured), content: Text(l10n.syncNotConfiguredMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SecondaryButton(icon: Icons.sync, label: l10n.dataSync, onTap: () => _syncData(context));
  }
}
