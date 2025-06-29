import 'package:flutter/material.dart';
import '../widgets/diary_file_manager.dart';

/// 单个日记维护页，可查看、编辑、保存指定日记内容
class DiaryEditPage extends StatelessWidget {
  final String fileName;
  const DiaryEditPage({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DiaryFileManager(),
      ),
    );
  }
}
