import 'package:flutter/material.dart';
import 'model_config_page.dart';
import 'prompt_config_page.dart';
import 'diary_mode_config_page.dart';
import 'qa_question_config_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            unselectedLabelStyle: TextStyle(fontSize: 13),
            tabs: [
              Tab(text: '模型', icon: Icon(Icons.memory, size: 18)),
              Tab(text: '提示词', icon: Icon(Icons.chat, size: 18)),
              Tab(text: '日记模式', icon: Icon(Icons.edit_note, size: 18)),
              Tab(text: '问答列表', icon: Icon(Icons.question_answer, size: 18)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ModelConfigPage(),
            PromptConfigPage(),
            DiaryModeConfigPage(),
            QaQuestionConfigPage(),
          ],
        ),
      ),
    );
  }
}
