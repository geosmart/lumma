import 'package:flutter/material.dart';
import 'model_config_page.dart';
import 'prompt_config_page.dart';
import 'diary_mode_config_page.dart';
import 'qa_question_config_page.dart';
import '../services/theme_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              Tab(icon: Icon(Icons.memory, size: 20)),
              Tab(icon: Icon(Icons.chat, size: 20)),
              Tab(icon: Icon(Icons.auto_stories, size: 20)),
              Tab(icon: Icon(Icons.question_answer, size: 20)),
              Tab(icon: Icon(Icons.palette, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ModelConfigPage(),
            PromptConfigPage(),
            DiaryModeConfigPage(),
            QaQuestionConfigPage(),
            _ThemeSettingsPage(),
          ],
        ),
      ),
    );
  }
}

// 主题设置页面
class _ThemeSettingsPage extends StatefulWidget {
  const _ThemeSettingsPage();

  @override
  State<_ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<_ThemeSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.backgroundGradient,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 页面标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: context.primaryTextColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '外观设置',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // 主题切换卡片
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: context.primaryTextColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '主题外观',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // 浅色主题
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFfdf7f0),
                          Color(0xFFf0e6d6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.borderColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.wb_sunny,
                      color: Color(0xFF8d6e63),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '浅色模式',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.primaryTextColor,
                    ),
                  ),
                  subtitle: Text(
                    '温暖淡雅的浅色主题',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.light,
                    groupValue: ThemeService.instance.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ThemeService.instance.setTheme(value);
                        setState(() {});
                      }
                    },
                  ),
                  onTap: () {
                    ThemeService.instance.setTheme(ThemeMode.light);
                    setState(() {});
                  },
                ),

                Divider(color: context.borderColor, height: 1),

                // 暗色主题
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1a1a2e),
                          Color(0xFF0f3460),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.borderColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    '暗色模式',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.primaryTextColor,
                    ),
                  ),
                  subtitle: Text(
                    '护眼深邃的暗色主题',
                    style: TextStyle(
                      color: context.secondaryTextColor,
                    ),
                  ),
                  trailing: Radio<ThemeMode>(
                    value: ThemeMode.dark,
                    groupValue: ThemeService.instance.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ThemeService.instance.setTheme(value);
                        setState(() {});
                      }
                    },
                  ),
                  onTap: () {
                    ThemeService.instance.setTheme(ThemeMode.dark);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 预览卡片
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '主题预览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // 模拟主页样式
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: context.backgroundGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: context.primaryButtonGradient,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lumma',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        Text(
                          'AI驱动的问答日记',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
