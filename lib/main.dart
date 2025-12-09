import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/llm_config_init.dart';
import 'service/theme_service.dart';
import 'generated/l10n/app_localizations.dart';
import 'routes/app_pages.dart';
import 'bindings/initial_binding.dart';
import 'app/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化默认配置
  await ensureConfig();

  print('[lumma] App init...');
  // 优雅加载环境变量，优先 .env.local，找不到则只加载 .env.release
  bool loaded = false;
  try {
    print('[lumma] 当前目录: ${Directory.current.path}');
    print('[lumma] .env.local exists: ${File('.env.local').existsSync()}');
    print('[lumma] .env.release exists: ${File('.env.release').existsSync()}');
    await dotenv.load(fileName: '.env.local');
    print('[lumma] 加载 .env.local 成功');
    loaded = true;
  } catch (e) {
    print('[lumma] 加载 .env.local 失败: $e');
  }
  if (!loaded) {
    try {
      await dotenv.load(fileName: '.env.release');
      print('[lumma] 加载 .env.release 成功');
      loaded = true;
    } catch (e) {
      print('[lumma] 加载 .env.release 失败: $e');
    }
  }
  // 环境变量控制配置优先级
  bool useLocal = false;
  if (loaded) {
    useLocal = dotenv.env['USE_LOCAL_CONFIG'] == 'true';
    print('[lumma] useLocalConfig: $useLocal');
  } else {
    print('[lumma][警告] 未加载到任何 .env 文件，强制使用正式配置');
  }
  // 不做任何文件/目录操作，直接进入主页
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
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
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
