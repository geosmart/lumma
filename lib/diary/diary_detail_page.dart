import 'package:flutter/material.dart';
import '../widgets/diary_file_manager.dart';
import '../generated/l10n/app_localizations.dart';

class DiaryDetailPage extends StatelessWidget {
  const DiaryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.diaryDetail)),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: DiaryFileManager(),
      ),
    );
  }
}
