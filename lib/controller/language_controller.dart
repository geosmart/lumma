import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/model/enums.dart';

/// GetX 语言控制器
class LanguageController extends GetxController {
  // 响应式当前语言
  final _currentLocale = const Locale('zh', 'CN').obs;

  Locale get currentLocale => _currentLocale.value;

  // 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'), // 简体中文
    Locale('en', 'US'), // 英语
  ];

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  /// 加载语言设置
  Future<void> _loadLanguage() async {
    final appConfig = await AppConfigService.load();
    final savedLanguage = appConfig.language;

    switch (savedLanguage) {
      case LanguageType.zh:
        _currentLocale.value = const Locale('zh', 'CN');
        break;
      case LanguageType.en:
        _currentLocale.value = const Locale('en', 'US');
        break;
    }
  }

  /// 设置语言
  Future<void> setLanguage(Locale locale) async {
    if (_currentLocale.value == locale) return;

    _currentLocale.value = locale;

    // 保存到 AppConfig
    final languageType = locale.languageCode == 'zh' ? LanguageType.zh : LanguageType.en;
    await AppConfigService.update((config) => config.language = languageType);

    // 使用 GetX 更新语言
    Get.updateLocale(locale);
  }

  /// 获取语言显示名称
  String getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '简体中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
}
