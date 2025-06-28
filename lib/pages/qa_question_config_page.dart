import 'package:flutter/material.dart';
import 'package:lumma/services/config_service.dart';

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
    _questionsFuture = _loadQuestions();
  }

  Future<List<String>> _loadQuestions() async {
    final questions = await ConfigService.loadQaQuestions();
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
      await ConfigService.saveQaQuestions(questions);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _questionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                return _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _controllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Question ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeQuestion(index),
                                ),
                              ],
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
                    label: const Text('添加'),
                    onPressed: _addQuestion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('保存'),
                    onPressed: _isLoading ? null : _saveQuestions,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16),
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
