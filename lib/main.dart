import 'package:flutter/material.dart';
import 'pages/main_tab_page.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[lumma] App init...');
  // 优雅加载环境变量，优先 .env.local，找不到则只加载 .env.release
  bool loaded = false;
  try {
    print('[lumma] 当前目录: \\${Directory.current.path}');
    print('[lumma] .env.local exists: \\${File('.env.local').existsSync()}');
    print('[lumma] .env.release exists: \\${File('.env.release').existsSync()}');
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lumma',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainTabPage(),
    );
  }
}
