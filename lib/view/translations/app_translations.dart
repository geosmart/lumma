import 'package:flutter/material.dart';
import 'en_us.dart';
import 'zh_cn.dart';

/// GetX 国际化配置
class AppTranslations {
  static const fallbackLocale = Locale('en', 'US');

  static final translations = [EnUS(), ZhCN()];

  static final supportedLocales = [const Locale('en', 'US'), const Locale('zh', 'CN')];
}
