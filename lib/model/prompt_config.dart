import 'package:lumma/model/enums.dart';
import 'prompt_constants.dart';

import 'timestamped.dart';

class PromptConfig extends Timestamped {
  String name;
  PromptCategory type;
  bool active;
  String content;

  PromptConfig({
    required this.name,
    required this.type,
    this.active = false,
    this.content = '',
    super.created,
    super.updated,
  });

  /// 问答提示词默认配置
  factory PromptConfig.qaDefault() => PromptConfig(
        name: getDefaultFileName(PromptCategory.chat),
        type: PromptCategory.chat,
        active: true,
        content: PromptConstants.defaultChatPrompt,
      );

  /// 总结提示词默认配置
  factory PromptConfig.summaryDefault() => PromptConfig(
        name: getDefaultFileName(PromptCategory.qa),
        type: PromptCategory.qa,
        active: false,
        content: PromptConstants.defaultSummaryPrompt,
      );

  /// 获取提示词类型对应的默认文件名
  static String getDefaultFileName(PromptCategory type) {
    switch (type) {
      case PromptCategory.chat:
        return '问答AI日记助手.md';
      case PromptCategory.qa:
        return '总结AI日记助手.md';
    }
  }

  factory PromptConfig.fromMap(Map map) => PromptConfig(
        name: map['name'] ?? '',
        type: map['type'] is PromptCategory
            ? map['type']
            : promptCategoryFromString(map['type'] ?? 'qa'),
        active: map['active'] ?? false,
        content: map['content'] ?? '',
        created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
        updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': promptCategoryToString(type),
        'active': active,
        'content': content,
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };
}
