import 'package:flutter/material.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/model/enums.dart';

class LanguageService extends ChangeNotifier {
  static LanguageService? _instance;

  static LanguageService get instance {
    _instance ??= LanguageService._();
    return _instance!;
  }

  LanguageService._();

  Locale _currentLocale = const Locale('zh', 'CN'); // 默认中文

  Locale get currentLocale => _currentLocale;

  // 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'), // 简体中文
    Locale('en', 'US'), // 英语
  ];

  Future<void> init() async {
    // 从 AppConfig 加载语言设置
    final appConfig = await AppConfigService.load();
    final savedLanguage = appConfig.language;

    switch (savedLanguage) {
      case LanguageType.zh:
        _currentLocale = const Locale('zh', 'CN');
        break;
      case LanguageType.en:
        _currentLocale = const Locale('en', 'US');
        break;
    }

    notifyListeners();
  }

  Future<void> setLanguage(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;

    // 立即保存到 AppConfig
    final languageType = locale.languageCode == 'zh' ? LanguageType.zh : LanguageType.en;
    await AppConfigService.update((config) => config.language = languageType);

    notifyListeners();
  }

  // 获取语言显示名称
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
