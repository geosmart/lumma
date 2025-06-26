import 'package:flutter/material.dart';
import 'diary_qa_page.dart';
import 'diary_chat_page.dart';
import 'settings_page.dart';
import '../widgets/diary_file_manager.dart';
import '../services/diary_mode_config_service.dart';
import '../services/diary_qa_title_service.dart';
import '../services/storage_service.dart';
import 'package:file_picker/file_picker.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> {
  @override
  void initState() {
    super.initState();
    // 不再检查或引导目录，直接加载
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听设置页返回后刷新
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      setState(() {});
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 直接渲染主界面，无需等待 _ready
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumma日记'),
        leading: IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // 只显示一个主按钮，根据模式进入对应页面
          FutureBuilder<String>(
            future: DiaryModeConfigService.loadDiaryMode(),
            builder: (context, snapshot) {
              final mode = snapshot.data ?? 'qa';
              return FutureBuilder<String>(
                future: getDiaryQaTitle(),
                builder: (context, titleSnap) {
                  final btnTitle = titleSnap.data ?? '';
                  final btnColor = mode == 'qa' ? Colors.blue[50] : Colors.green[50];
                  final btnFg = mode == 'qa' ? Colors.blue : Colors.green;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => mode == 'qa' ? const DiaryQaPage() : const DiaryChatPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: btnColor,
                              foregroundColor: btnFg,
                            ),
                            child: Text(btnTitle),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DiaryFileManager(),
            ),
          ),
        ],
      ),
    );
  }
}
