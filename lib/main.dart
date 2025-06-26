import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/storage_service.dart';
import 'pages/main_tab_page.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/config_service.dart';

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
  await ConfigService.ensureDefaultConfig();
  print('[lumma] ensureDefaultConfig 完成');
  // 检查并弹窗选择存储目录
  String? diaryDir = await StorageService.getUserDiaryDir();
  print('[lumma] 当前存储目录: $diaryDir');
  if (diaryDir == null) {
    diaryDir = await _pickDiaryDir();
    print('[lumma] 用户选择目录: $diaryDir');
    if (diaryDir != null) {
      await StorageService.setUserDiaryDir(diaryDir);
      print('[lumma] 存储目录已保存');
    }
  }
  print('[lumma] runApp...');
  runApp(const MyApp());
}

Future<String?> _pickDiaryDir() async {
  final result = await FilePicker.platform.getDirectoryPath(dialogTitle: '请选择日记存储目录');
  return result;
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
