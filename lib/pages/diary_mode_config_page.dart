import 'package:flutter/material.dart';
import '../services/diary_mode_config_service.dart';
import '../config/settings_ui_config.dart';

class DiaryModeConfigPage extends StatefulWidget {
  const DiaryModeConfigPage({super.key});

  @override
  State<DiaryModeConfigPage> createState() => _DiaryModeConfigPageState();
}

class _DiaryModeConfigPageState extends State<DiaryModeConfigPage> {
  // 'qa': 固定问答，'chat': AI问答
  String _mode = 'qa';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await DiaryModeConfigService.loadDiaryMode();
    setState(() {
      _mode = mode.toString();
      _loading = false;
    });
  }

  Future<void> _setMode(String mode) async {
    setState(() {
      _mode = mode;
    });
    await DiaryModeConfigService.saveDiaryMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(4),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(
              _mode == 'qa' ? Icons.check_circle : Icons.circle_outlined,
              color: _mode == 'qa' ? Colors.green : null,
            ),
            title: const Text('固定问答'),
            subtitle: const Text('逐条回答预设问题，生成结构化日记'),
            onTap: () => _setMode('qa'),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(
              _mode == 'chat' ? Icons.check_circle : Icons.circle_outlined,
              color: _mode == 'chat' ? Colors.green : null,
            ),
            title: const Text('AI问答'),
            subtitle: const Text('按问答提示词与AI对话，生成自定义日记'),
            onTap: () => _setMode('chat'),
          ),
        ),
      ],
    );
  }
}
