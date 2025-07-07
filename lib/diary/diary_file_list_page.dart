import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../widgets/diary_file_manager.dart';
import '../config/theme_service.dart';

/// Diary management page, supporting selection, creation, and deletion of diary files
class DiaryFileListPage extends StatelessWidget {
  const DiaryFileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.diaryFileListTitle,
          style: TextStyle(
            color: context.primaryTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: context.primaryTextColor,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.backgroundGradient,
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: DiaryFileManager(),
        ),
      ),
    );
  }
}
