import 'package:flutter/material.dart';
import '../config/config_service.dart';
import '../config/theme_service.dart';
import '../config/settings_ui_config.dart';
import 'qa_questions_service.dart';

class QaQuestionConfigPage extends StatefulWidget {
  const QaQuestionConfigPage({super.key});

  @override
  _QaQuestionConfigPageState createState() => _QaQuestionConfigPageState();
}

class _QaQuestionConfigPageState extends State<QaQuestionConfigPage> {
  late Future<List<String>> _questionsFuture;
  final List<TextEditingController> _controllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _initAndLoadQuestions();
  }

  Future<List<String>> _initAndLoadQuestions() async {
    // 保证有默认值并持久化
    await QaQuestionsService.init();
    return _loadQuestions();
  }

  Future<List<String>> _loadQuestions() async {
    final config = await AppConfigService.load();
    final questions = config.qaQuestions;
    _controllers.clear();
    for (var q in questions) {
      _controllers.add(TextEditingController(text: q));
    }
    return questions;
  }

  void _addQuestion() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _controllers.removeAt(index);
    });
  }

  Future<void> _saveQuestions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final questions = _controllers.map((c) => c.text).toList();
      await AppConfigService.update((c) => c.qaQuestions = List<String>.from(questions));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questions saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save questions: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      child: Column(
        children: [
          // 页面标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.question_answer,
                  color: context.primaryTextColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '问题列表',
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _questionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: SettingsUiConfig.titleFontSize,
                      ),
                    ),
                  );
                }

                return _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    : _controllers.isEmpty
                        ? Center(
                            child: Text(
                              '暂无问题',
                              style: TextStyle(
                                color: context.secondaryTextColor,
                                fontSize: SettingsUiConfig.titleFontSize,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _controllers.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.cardBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _controllers[index],
                                          style: TextStyle(
                                            color: context.primaryTextColor,
                                            fontSize: SettingsUiConfig.titleFontSize,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: '问题 ${index + 1}',
                                            labelStyle: TextStyle(
                                              color: context.secondaryTextColor,
                                              fontSize: SettingsUiConfig.subtitleFontSize,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: context.borderColor,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: context.borderColor,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Theme.of(context).colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        onPressed: () => _removeQuestion(index),
                                        tooltip: '删除',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('添加问题'),
                    onPressed: _addQuestion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(
                        fontSize: SettingsUiConfig.titleFontSize,
                        fontWeight: SettingsUiConfig.titleFontWeight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('保存设置'),
                    onPressed: _isLoading ? null : _saveQuestions,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(
                        fontSize: SettingsUiConfig.titleFontSize,
                        fontWeight: SettingsUiConfig.titleFontWeight,
                      ),
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
