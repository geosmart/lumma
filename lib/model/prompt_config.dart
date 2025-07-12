import 'package:lumma/model/enums.dart';
import 'prompt_constants.dart';
import '../config/language_service.dart';

import 'timestamped.dart';

class PromptConfig extends Timestamped {
  String name;
  PromptCategory type;
  bool active;
  String content;
  bool isSystem; // 新增：是否为系统级提示词

  PromptConfig({
    required this.name,
    required this.type,
    this.active = false,
    this.content = '',
    this.isSystem = false, // 默认不是系统级
    super.created,
    super.updated,
  });

  /// 问答提示词默认配置
  factory PromptConfig.qaDefault() => PromptConfig(
        name: getDefaultFileName(PromptCategory.chat),
        type: PromptCategory.chat,
        active: true,
        content: PromptConstants.getDefaultChatPrompt(),
        isSystem: true, // 系统级提示词
      );

  /// 总结提示词默认配置
  factory PromptConfig.summaryDefault() => PromptConfig(
        name: getDefaultFileName(PromptCategory.qa),
        type: PromptCategory.qa,
        active: false,
        content: PromptConstants.getDefaultSummaryPrompt(),
        isSystem: true, // 系统级提示词
      );

  /// 获取提示词类型对应的默认文件名
  static String getDefaultFileName(PromptCategory type) {
    // 导入语言服务
    final languageService = LanguageService.instance;
    final currentLanguage = languageService.currentLocale.languageCode;

    final isZh = currentLanguage == 'zh';

    switch (type) {
      case PromptCategory.chat:
        return isZh ? '问答AI日记助手.md' : 'QA Diary Assistant.md';
      case PromptCategory.qa:
        return isZh ? '总结AI日记助手.md' : 'Summary Diary Assistant.md';
    }
  }

  factory PromptConfig.fromMap(Map map) => PromptConfig(
        name: map['name'] ?? '',
        type: map['type'] is PromptCategory
            ? map['type']
            : promptCategoryFromString(map['type'] ?? 'qa'),
        active: map['active'] ?? false,
        content: map['content'] ?? '',
        isSystem: map['isSystem'] ?? false, // 新增字段
        created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
        updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': promptCategoryToString(type),
        'active': active,
        'content': content,
        'isSystem': isSystem, // 新增字段
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };
}
