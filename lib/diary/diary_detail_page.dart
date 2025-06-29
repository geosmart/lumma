import 'package:flutter/material.dart';
import '../widgets/diary_file_manager.dart';

class DiaryDetailPage extends StatelessWidget {
  const DiaryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日记详情')),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: DiaryFileManager(),
      ),
    );
  }
}
