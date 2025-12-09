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
import 'package:lumma/model/enums.dart';
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
    // DiaryEditPage 需要 fileName 参数，通过 Get.arguments['fileName'] 传递
    GetPage(
      name: AppRoutes.diaryEdit,
      page: () => DiaryEditPage(
        fileName: Get.arguments?['fileName'] ?? '',
      ),
    ),
    // DiaryContentPage 需要 fileName 参数，通过 Get.arguments['fileName'] 传递
    GetPage(
      name: AppRoutes.diaryContent,
      page: () => DiaryContentPage(
        fileName: Get.arguments?['fileName'] ?? '',
      ),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
    ),
    // LlmConfigPage 是 StatefulWidget，不能用 const
    GetPage(
      name: AppRoutes.llmConfig,
      page: () => const LLMConfigPage(),
    ),
    // LlmEditPage 可以接收可选参数
    GetPage(
      name: AppRoutes.llmEdit,
      page: () => LLMEditPage(
        config: Get.arguments?['config'],
        readOnly: Get.arguments?['readOnly'] ?? false,
      ),
    ),
    GetPage(
      name: AppRoutes.promptConfig,
      page: () => const PromptConfigPage(),
    ),
    // PromptEditPage 需要 activeCategory 参数（PromptCategory 枚举类型）
    GetPage(
      name: AppRoutes.promptEdit,
      page: () => PromptEditPage(
        activeCategory: Get.arguments?['activeCategory'] ?? PromptCategory.chat,
        file: Get.arguments?['file'],
        readOnly: Get.arguments?['readOnly'] ?? false,
        initialContent: Get.arguments?['initialContent'],
        initialName: Get.arguments?['initialName'],
        isSystem: Get.arguments?['isSystem'] ?? false,
      ),
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
