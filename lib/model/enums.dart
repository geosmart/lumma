import 'timestamped.dart';

enum DiaryMode { qa, chat }

String diaryModeToString(DiaryMode mode) {
  switch (mode) {
    case DiaryMode.qa:
      return 'qa';
    case DiaryMode.chat:
      return 'chat';
  }
}

DiaryMode diaryModeFromString(String value) {
  switch (value) {
    case 'qa':
      return DiaryMode.qa;
    case 'summary':
      return DiaryMode.chat;
    default:
      return DiaryMode.qa;
  }
}

// 提示词分类枚举
enum PromptCategory {
  qa,
  summary
}

// 获取提示词分类显示名称
String promptCategoryToDisplayName(PromptCategory category) {
  switch (category) {
    case PromptCategory.qa:
      return '问答';
    case PromptCategory.summary:
      return '总结';
  }
}

// 将提示词分类枚举转换为字符串
String promptCategoryToString(PromptCategory category) {
  switch (category) {
    case PromptCategory.qa:
      return 'qa';
    case PromptCategory.summary:
      return 'summary';
  }
}

// 根据字符串获取提示词分类枚举
PromptCategory promptCategoryFromString(String value) {
  switch (value) {
    case 'qa':
      return PromptCategory.qa;
    case 'summary':
      return PromptCategory.summary;
    default:
      return PromptCategory.qa;
  }
}

enum ThemeModeType { light, dark }

String themeModeTypeToString(ThemeModeType mode) {
  switch (mode) {
    case ThemeModeType.light:
      return 'light';
    case ThemeModeType.dark:
      return 'dark';
  }
}

ThemeModeType themeModeTypeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeModeType.light;
    case 'dark':
      return ThemeModeType.dark;
    default:
      return ThemeModeType.light;
  }
}
