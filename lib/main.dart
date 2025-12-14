import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'config/llm_config_init.dart';
import 'service/theme_service.dart';
import 'generated/l10n/app_localizations.dart';
import 'view/routes/app_pages.dart';
import 'view/bindings/initial_binding.dart';
import 'view/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化默认配置
  await ensureConfig();

  print('[lumma] App init...');
  print('[lumma] runApp...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumma',
      // GetX 主题配置
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // 默认主题，将由 ThemeController 控制
      // GetX 国际化配置
      translations: AppTranslations.translations.first,
      locale: const Locale('zh', 'CN'), // 默认语言，将由 LanguageController 控制
      fallbackLocale: AppTranslations.fallbackLocale,
      // Flutter 原生国际化支持（为了支持 AppLocalizations）
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
      // GetX 路由配置
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      // 全局依赖注入
      initialBinding: InitialBinding(),
      // 默认过渡动画
      defaultTransition: Transition.cupertino,
    );
  }
}
