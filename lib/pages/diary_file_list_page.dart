import 'package:flutter/material.dart';
import '../widgets/diary_file_manager.dart';

/// 日记管理页面，支持选择、增删日记文件
class DiaryFileListPage extends StatelessWidget {
  const DiaryFileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日记管理')),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: DiaryFileManager(),
      ),
    );
  }
}
