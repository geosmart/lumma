import 'package:flutter/material.dart';
import '../config/config_service.dart';
import '../model/enums.dart';

/// 主题管理服务
class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static ThemeService? _instance;
  static ThemeService get instance => _instance ??= ThemeService._();

  ThemeService._();

  /// 初始化主题设置
  Future<void> init() async {
    final appConfig = await AppConfigService.load();
    final savedTheme = appConfig.theme;
    _themeMode = savedTheme == ThemeModeType.dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// 切换主题
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveTheme();
    notifyListeners();
  }

  /// 设置主题
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveTheme();
      notifyListeners();
    }
  }

  /// 保存主题设置
  Future<void> _saveTheme() async {
    await AppConfigService.update(
      (c) => c.theme = _themeMode == ThemeMode.dark ? ThemeModeType.dark : ThemeModeType.light,
    );
  }

  /// 新增: 持久化主题配置到 lumma_config.json
  Future<void> save() async {
    await _saveTheme();
  }
}

/// 应用主题配置
class AppTheme {
  // 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD7CCC8),
        secondary: Color(0xFFd4a574),
        surface: Color(0xFFfdf7f0),
        primaryContainer: Color(0xFF9FA8DA), // 蓝紫色，和暗色主题统一
      ),
      scaffoldBackgroundColor: const Color(0xFFfdf7f0),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFfdf7f0),
        foregroundColor: Color(0xFF5d4037),
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9FA8DA), // 跟随primaryContainer
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  // 暗色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9FA8DA), // 淡雅的蓝紫色，与按钮颜色一致
        secondary: Color(0xFF764ba2),
        surface: Color(0xFF1a1a2e),
        primaryContainer: Color(0xFF232a34), // 新增主按钮背景色
      ),
      scaffoldBackgroundColor: const Color(0xFF1a1a2e),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1a1a2e), foregroundColor: Colors.white, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF232a34), // 跟随primaryContainer
          foregroundColor: Colors.white, // 深色文字，提高对比度
        ),
      ),
    );
  }
}

/// 主题颜色扩展
extension ThemeColors on BuildContext {
  // 背景渐变色
  List<Color> get backgroundGradient {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    if (isDark) {
      // 顶部深灰蓝 → 蓝紫 → 深蓝 → 深青，底部不再高亮
      return const [
        Color(0xFF232526), // 顶部深灰蓝
        Color(0xFF414345), // 蓝紫
        Color(0xFF232a34), // 深蓝青
        Color(0xFF16213e), // 底部深蓝
      ];
    } else {
      return const [
        Color(0xFFfdf7f0), // 温暖米白
        Color(0xFFf7f1e8), // 淡雅米色
        Color(0xFFf0e6d6), // 浅褐米色
      ];
    }
  }

  // 主要文字颜色
  Color get primaryTextColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? Colors.white : const Color(0xFF5d4037);
  }

  // 次要文字颜色
  Color get secondaryTextColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.8) : const Color(0xFF8d6e63);
  }

  // 卡片背景色
  Color get cardBackgroundColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.7);
  }

  // 边框颜色
  Color get borderColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.2) : const Color(0xFF8d6e63).withOpacity(0.2);
  }

  // 主要按钮渐变色
  List<Color> get primaryButtonGradient {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    if (isDark) {
      // 采用icon主色的青绿渐变，现代感更强
      return const [Color(0xFF43e97b), Color(0xFF38f9d7)];
    } else {
      return const [
        Color(0xFFd4a574), // 温暖金棕
        Color(0xFFc49574), // 深一点的金棕
      ];
    }
  }

  // 装饰元素颜色
  Color get decorationColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    // 用更通透的蓝紫色，呼应icon
    return isDark ? const Color(0xFF667eea).withOpacity(0.18) : Colors.black.withOpacity(0.03);
  }
}
