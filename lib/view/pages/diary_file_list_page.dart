import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/view/widgets/diary_file_manager.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/view/routes/app_routes.dart';

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
        iconTheme: IconThemeData(color: context.primaryTextColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: l10n.calendarView,
            onPressed: () => Get.toNamed(AppRoutes.diaryCalendar),
          ),
          IconButton(
            icon: const Icon(Icons.view_timeline),
            tooltip: l10n.listView,
            onPressed: () => Get.toNamed(AppRoutes.diaryList),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: context.backgroundGradient,
          ),
        ),
        child: const Padding(padding: EdgeInsets.all(16.0), child: DiaryFileManager()),
      ),
    );
  }
}
