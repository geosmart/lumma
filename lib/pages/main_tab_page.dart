import 'package:flutter/material.dart';
import 'diary_chat_page.dart';
import 'settings_page.dart';
import 'diary_file_list_page.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 移除AppBar标题
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFe0e7ff), // 柔和蓝紫
                  Color(0xFFf8fafc), // 亮灰
                  Color(0xFFfceabb), // 柔和黄
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32), // LOGO与标题间距
              // LOGO区（极简风格）
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(Icons.menu_book, size: 48, color: Colors.black87),
              ),
              const SizedBox(height: 28), // LOGO与标题间距
              const Text(
                'Lumma',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16), // 标题与副标题间距
              const Text(
                'AI驱动的问答日记体验',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              // 按钮区：两排布局
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // 第一排：系统设置、日记列表
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _HomeActionButton(
                          icon: Icons.settings,
                          label: '系统设置',
                          color: Colors.black87,
                          width: 140,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsPage()),
                            );
                          },
                        ),
                        const SizedBox(width: 32),
                        _HomeActionButton(
                          icon: Icons.menu_book,
                          label: '日记列表',
                          color: Colors.black87,
                          width: 140,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const DiaryFileListPage()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24), // 两排按钮间距
                    // 第二排：主操作按钮，日期换行在上，“这就开始”在下
                    Center(
                      child: _HomeActionButton(
                        icon: null, // 不显示主按钮左侧icon
                        label: '这就开始',
                        color: Colors.black87,
                        width: 312,
                        big: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DiaryChatPage()),
                          );
                        },
                        extraWidget: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, size: 20, color: Colors.black45),
                                const SizedBox(width: 4),
                                Text(
                                  _TodayDateDisplay.inlineString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10), // 增加换行间距
                          ],
                        ),
                        verticalLayout: true,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ],
      ),
    );
  }
}

// _HomeActionButton 支持自定义宽度和高度，三个按钮高度统一
class _HomeActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool big;
  final double? width;
  final Widget? extraWidget;
  final bool verticalLayout;
  const _HomeActionButton({
    this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.big = false,
    this.width,
    this.extraWidget,
    this.verticalLayout = false,
  });

  @override
  Widget build(BuildContext context) {
    final double size = width ?? (big ? 140 : 90);
    final double height = big ? 92 : 66; // big按钮高度提升到92
    final double iconSize = big ? 32 : 24;
    final double fontSize = big ? 18 : 15;
    final children = <Widget>[
      if (icon != null) ...[
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 10),
      ],
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (extraWidget != null) ...[
        verticalLayout ? const SizedBox(height: 6) : const SizedBox(width: 10),
        extraWidget!,
      ],
    ];
    return Material(
      color: Colors.black.withOpacity(big ? 0.07 : 0.04),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: size,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: verticalLayout
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (extraWidget != null) extraWidget!,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: iconSize, color: color),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                ),
        ),
      ),
    );
  }
}

// 今日日期组件（静态方法返回字符串）
class _TodayDateDisplay {
  static String inlineString() {
    final now = DateTime.now();
    return "${now.day}  ${now.year}年${now.month}月";
  }
}
