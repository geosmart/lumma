import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/service/random_diary_service.dart';
import 'package:lumma/util/sync_service.dart';
import 'package:lumma/model/enums.dart';
import 'package:lumma/view/routes/app_routes.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  DiaryEntryWithDate? _currentEntry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSyncConfig();
    _loadRandomDiaryEntry();
  }

  Future<void> _checkSyncConfig() async {
    developer.log('应用启动时检查同步配置', name: 'MainTabPage');
    final isSyncConfigured = await SyncService.isSyncConfigured();
    developer.log('同步配置状态: ${isSyncConfigured ? "已配置" : "未配置"}', name: 'MainTabPage');
  }

  Future<void> _loadRandomDiaryEntry() async {
    setState(() => _isLoading = true);

    final entry = await RandomDiaryService.getRandomDiaryEntry(context);

    if (mounted) {
      setState(() {
        _currentEntry = entry;
        _isLoading = false;
      });
    }
  }

  void _loadNextEntry() {
    _loadRandomDiaryEntry();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 将SafeArea放在body内容之外或具体控制，以便底部导航栏背景能延伸到底部（如果需要沉浸式）
      // 这里为了简单，我们保持 SafeArea，但让底部栏撑满宽度
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.backgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false, // 关闭底部SafeArea，由我们自己控制Padding，这样底部栏可以沉底
          child: Column(
            children: [
              // 1. Header: Logo + Slogan
              // 增加 flex 权重 (2 -> 3)，让上部占据更多空间，从而把下面的内容"往下压"
              Expanded(
                flex: 3,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      SvgPicture.asset(
                        'assets/icon/icon.svg',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      // App Name
                      Text(
                        'Lumma',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 42,
                            color: context.primaryTextColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            shadows: const [Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black12)]
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Slogan
                      Text(
                        AppLocalizations.of(context)!.appSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: context.secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Memory Card
              // 增加 flex 权重 (2 -> 4)，给卡片更多展示空间
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 额外增加一个占位，强制让卡片与上方的 Slogan 拉开距离
                      const SizedBox(height: 24),
                      Expanded(child: _buildMemoryCard(context)),
                      const SizedBox(height: 16), // 卡片下方的间距
                    ],
                  ),
                ),
              ),

              // 3. 底部区域
              // 包含 "开始写日记" 按钮 和 底部导航栏
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Start Writing Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24), // 与卡片对齐
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () async {
                              final mode = await AppConfigService.loadDiaryMode();
                              if (mode == DiaryMode.chat) {
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
                                  const Icon(Icons.add, color: Colors.white, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.startWritingDiary,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Button与底部导航栏之间的间距
                    const SizedBox(height: 20),

                    // Bottom Navigation Bar
                    _buildBottomNavigation(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context) {
    if (_isLoading) {
      return _buildGlassCard(
        child: Center(
          child: CircularProgressIndicator(
            color: context.primaryTextColor.withOpacity(0.5),
          ),
        ),
      );
    }

    if (_currentEntry == null) {
      return _buildGlassCard(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_edu_outlined,
                size: 48,
                color: context.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No memories yet',
                style: TextStyle(
                  fontSize: 16,
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start writing to create your first memory',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.secondaryTextColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildGlassCard(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time and Title in one row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  Text(
                    _currentEntry!.getDisplayTime(),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      _currentEntry!.getDisplayTitle(),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.primaryTextColor,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 30), // 为箭头留出空间
                ],
              ),

              const SizedBox(height: 12),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _currentEntry!.getDisplayContent(),
                    style: TextStyle(
                      fontSize: 13,
                      color: context.primaryTextColor.withOpacity(0.75),
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Next Button
          Positioned(
            top: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _loadNextEntry,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: context.primaryTextColor.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.cardBackgroundColor.withOpacity(0.05),
          width: 1,
        )
      ),
      child: child,
    );
  }

  // 优化后的底部导航栏
  Widget _buildBottomNavigation(BuildContext context) {
    // 获取底部安全区域高度，用于padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity, // 撑满宽度
      // 上方留一点padding，下方加上安全区域的padding
      padding: EdgeInsets.only(top: 12, bottom: bottomPadding > 0 ? bottomPadding : 12),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor, // 使用卡片背景色（通常是半透明或白色）
        // 仅顶部添加边框，模拟原生 TabBar 效果
        border: Border(
          top: BorderSide(
            color: context.borderColor,
            width: 1,
          ),
        ),
        // 可选：添加一点顶部阴影增加层次感
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, // 均匀分布
        children: [
          _NavButton(
            icon: Icons.calendar_today_outlined,
            label: AppLocalizations.of(context)!.calendarView,
            onTap: () => Get.toNamed(AppRoutes.diaryCalendar),
          ),
          _NavButton(
            icon: Icons.cloud_sync_outlined,
            label: AppLocalizations.of(context)!.dataSync,
            onTap: () => SyncService.syncDataWithContext(context),
          ),
          _NavButton(
            icon: Icons.settings_outlined,
            label: AppLocalizations.of(context)!.settings,
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 移除 Expanded，因为 Row 用了 spaceAround，按钮大小自适应即可
    // 如果想要更大的点击热区，可以用 Expanded 包裹，但这里为了精致感，仅保持内容
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4), // 增加横向点击区域
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: context.primaryTextColor,
              size: 24, // 稍微调大一点图标
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
