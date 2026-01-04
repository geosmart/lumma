/// 应用路由名称定义
abstract class AppRoutes {
  // 主页
  static const main = '/';

  // 日记相关
  static const diaryTimeline = '/diary/timeline';
  static const diaryCalendar = '/diary/calendar';
  static const diaryFileList = '/diary/file-list';
  static const diaryList = '/diary/list';
  static const diaryDetail = '/diary/detail';
  static const diaryEdit = '/diary/edit';
  static const diaryContent = '/diary/content';

  // 配置相关
  static const settings = '/settings';
  static const diaryModeConfig = '/settings/diary-mode-config';
  static const syncConfig = '/settings/sync-config';
}
