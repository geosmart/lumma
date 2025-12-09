import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumma/config/config_service.dart';
import 'package:lumma/model/enums.dart';

/// GetX 主题控制器
class ThemeController extends GetxController {
  // 响应式主题模式
  final _themeMode = ThemeMode.dark.obs;

  ThemeMode get themeMode => _themeMode.value;

  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  /// 加载主题设置
  Future<void> _loadTheme() async {
    final appConfig = await AppConfigService.load();
    final savedTheme = appConfig.theme;
    _themeMode.value = savedTheme == ThemeModeType.dark ? ThemeMode.dark : ThemeMode.light;
  }

  /// 切换主题
  Future<void> toggleTheme() async {
    _themeMode.value = _themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _saveTheme();
    // GetX 会自动更新 UI
    Get.changeThemeMode(_themeMode.value);
  }

  /// 设置主题
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode.value != mode) {
      _themeMode.value = mode;
      await _saveTheme();
      Get.changeThemeMode(_themeMode.value);
    }
  }

  /// 保存主题设置
  Future<void> _saveTheme() async {
    await AppConfigService.update(
      (c) => c.theme = _themeMode.value == ThemeMode.dark ? ThemeModeType.dark : ThemeModeType.light,
    );
  }
}
