/// 应用路由名称定义
abstract class AppRoutes {
  // 主页
  static const main = '/';

  // 日记相关
  static const diaryChat = '/diary/chat';
  static const diaryQa = '/diary/qa';
  static const diaryCalendar = '/diary/calendar';
  static const diaryFileList = '/diary/file-list';
  static const diaryDetail = '/diary/detail';
  static const diaryEdit = '/diary/edit';
  static const diaryContent = '/diary/content';

  // 配置相关
  static const settings = '/settings';
  static const llmConfig = '/settings/llm-config';
  static const llmEdit = '/settings/llm-edit';
  static const promptConfig = '/settings/prompt-config';
  static const promptEdit = '/settings/prompt-edit';
  static const categoryConfig = '/settings/category-config';
  static const diaryModeConfig = '/settings/diary-mode-config';
  static const syncConfig = '/settings/sync-config';
  static const qaQuestionConfig = '/settings/qa-question-config';
}
