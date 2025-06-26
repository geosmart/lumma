import 'package:flutter/material.dart';
import '../services/diary_mode_config_service.dart';

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
          padding: EdgeInsets.all(16),
          child: Text('日记输入模式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(
              _mode == 'qa' ? Icons.check_circle : Icons.circle_outlined,
              color: _mode == 'qa' ? Colors.green : null,
            ),
            title: const Text('固定问答（结构化引导）'),
            subtitle: const Text('逐条回答预设问题，适合新手或需要结构化梳理时'),
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
            title: const Text('AI问答（自由对话）'),
            subtitle: const Text('与AI自由对话，适合有经验用户或灵活记录'),
            onTap: () => _setMode('chat'),
          ),
        ),
      ],
    );
  }
}
