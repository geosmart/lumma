import 'package:get/get.dart';
import 'package:lumma/main_page.dart';
import 'package:lumma/diary/diary_chat_page.dart';
import 'package:lumma/diary/diary_qa_page.dart';
import 'package:lumma/diary/diary_calendar_page.dart';
import 'package:lumma/diary/diary_file_list_page.dart';
import 'package:lumma/diary/diary_detail_page.dart';
import 'package:lumma/diary/diary_edit_page.dart';
import 'package:lumma/diary/diary_content_page.dart';
import 'package:lumma/config/settings_page.dart';
import 'package:lumma/config/llm_config_page.dart';
import 'package:lumma/config/llm_edit_page.dart';
import 'package:lumma/config/prompt_config_page.dart';
import 'package:lumma/config/prompt_edit_page.dart';
import 'package:lumma/config/category_config_page.dart';
import 'package:lumma/config/diary_mode_config_page.dart';
import 'package:lumma/config/sync_config_page.dart';
import 'package:lumma/diary/qa_question_config_page.dart';
import 'app_routes.dart';

/// GetX 页面路由配置
class AppPages {
  static const initial = AppRoutes.main;

  static final routes = [
    GetPage(
      name: AppRoutes.main,
      page: () => const MainTabPage(),
    ),
    GetPage(
      name: AppRoutes.diaryChat,
      page: () => const DiaryChatPage(),
    ),
    GetPage(
      name: AppRoutes.diaryQa,
      page: () => const DiaryQaPage(),
    ),
    GetPage(
      name: AppRoutes.diaryCalendar,
      page: () => const DiaryCalendarPage(),
    ),
    GetPage(
      name: AppRoutes.diaryFileList,
      page: () => const DiaryFileListPage(),
    ),
    GetPage(
      name: AppRoutes.diaryDetail,
      page: () => const DiaryDetailPage(),
    ),
    GetPage(
      name: AppRoutes.diaryEdit,
      page: () => const DiaryEditPage(),
    ),
    GetPage(
      name: AppRoutes.diaryContent,
      page: () => const DiaryContentPage(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
    ),
    GetPage(
      name: AppRoutes.llmConfig,
      page: () => const LlmConfigPage(),
    ),
    GetPage(
      name: AppRoutes.llmEdit,
      page: () => const LlmEditPage(),
    ),
    GetPage(
      name: AppRoutes.promptConfig,
      page: () => const PromptConfigPage(),
    ),
    GetPage(
      name: AppRoutes.promptEdit,
      page: () => const PromptEditPage(),
    ),
    GetPage(
      name: AppRoutes.categoryConfig,
      page: () => const CategoryConfigPage(),
    ),
    GetPage(
      name: AppRoutes.diaryModeConfig,
      page: () => const DiaryModeConfigPage(),
    ),
    GetPage(
      name: AppRoutes.syncConfig,
      page: () => const SyncConfigPage(),
    ),
    GetPage(
      name: AppRoutes.qaQuestionConfig,
      page: () => const QaQuestionConfigPage(),
    ),
  ];
}
