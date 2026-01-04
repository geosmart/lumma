import 'package:get/get.dart';
import 'package:lumma/view/pages/main_page.dart';
import 'package:lumma/view/pages/diary_timeline_page.dart';
import 'package:lumma/view/pages/diary_calendar_page.dart';
import 'package:lumma/view/pages/diary_file_list_page.dart';
import 'package:lumma/view/pages/diary_list_page.dart';
import 'package:lumma/view/pages/diary_detail_page.dart';
import 'package:lumma/view/pages/diary_edit_page.dart';
import 'package:lumma/view/pages/diary_content_page.dart';
import 'package:lumma/view/pages/settings_page.dart';
import 'package:lumma/view/pages/diary_mode_config_page.dart';
import 'package:lumma/view/pages/sync_config_page.dart';
import 'app_routes.dart';

/// GetX 页面路由配置
class AppPages {
  static const initial = AppRoutes.main;

  static final routes = [
    GetPage(name: AppRoutes.main, page: () => const MainTabPage()),
    GetPage(name: AppRoutes.diaryTimeline, page: () => const DiaryTimelinePage()),
    GetPage(name: AppRoutes.diaryCalendar, page: () => const DiaryCalendarPage()),
    GetPage(name: AppRoutes.diaryFileList, page: () => const DiaryFileListPage()),
    GetPage(name: AppRoutes.diaryList, page: () => const DiaryListPage()),
    GetPage(name: AppRoutes.diaryDetail, page: () => const DiaryDetailPage()),
    // DiaryEditPage 需要 fileName 参数，通过 Get.arguments['fileName'] 传递
    GetPage(
      name: AppRoutes.diaryEdit,
      page: () => DiaryEditPage(fileName: Get.arguments?['fileName'] ?? ''),
    ),
    // DiaryContentPage 需要 fileName 参数，通过 Get.arguments['fileName'] 传递
    GetPage(
      name: AppRoutes.diaryContent,
      page: () => DiaryContentPage(fileName: Get.arguments?['fileName'] ?? ''),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
    GetPage(name: AppRoutes.diaryModeConfig, page: () => const DiaryModeConfigPage()),
    GetPage(name: AppRoutes.syncConfig, page: () => const SyncConfigPage()),
  ];
}
