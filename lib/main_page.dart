import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'generated/l10n/app_localizations.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/util/sync_service.dart';
import 'model/enums.dart';
import 'package:lumma/view/routes/app_routes.dart';

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
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () async {
                    final mode = await AppConfigService.loadDiaryMode();
                    if (mode == DiaryMode.chat) {
                      // 使用 GetX 路由导航
                      Get.toNamed(AppRoutes.diaryChat);
                    } else if (mode == DiaryMode.timeline) {
                      Get.toNamed(AppRoutes.diaryTimeline);
                    } else {
                      Get.toNamed(AppRoutes.diaryQa);
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.record_voice_over, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.startWritingDiary.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 次要操作按钮
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: _SecondaryButton(
                        icon: Icons.list_alt,
                        label: AppLocalizations.of(context)!.diaryList,
                        onTap: () {
                          // 使用 GetX 路由导航
                          Get.toNamed(AppRoutes.diaryFileList);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: _SecondaryButton(
                        icon: Icons.calendar_today,
                        label: AppLocalizations.of(context)!.calendarView,
                        onTap: () {
                          // 使用 GetX 路由导航
                          Get.toNamed(AppRoutes.diaryCalendar);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 用 _SyncButton 替换原来的"数据同步"按钮
                    SizedBox(
                      width: 100,
                      child: _SyncButton(),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: _SecondaryButton(
                        icon: Icons.settings,
                        label: AppLocalizations.of(context)!.settings,
                        onTap: () {
                          // 使用 GetX 路由导航
                          Get.toNamed(AppRoutes.settings);
                        },
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 60),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _SecondaryButton(
      icon: Icons.sync,
      label: l10n.dataSync,
      onTap: () => SyncService.syncDataWithContext(context),
    );
  }
}
