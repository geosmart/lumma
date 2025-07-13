import 'package:flutter/material.dart';
import '../widgets/diary_file_manager.dart';

/// Single diary maintenance page, can view, edit, and save specified diary content
class DiaryEditPage extends StatelessWidget {
  final String fileName;
  const DiaryEditPage({super.key, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: Padding(padding: const EdgeInsets.all(8.0), child: DiaryFileManager()),
    );
  }
}
