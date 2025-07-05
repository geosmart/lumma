// 测试 DiaryContentService 的排序功能
import 'package:flutter/material.dart';
import 'diary_content_service.dart';

void main() {
  testSummaryFirst();
}

void testSummaryFirst() {
  // 模拟日记内容
  const testContent = '''
## 15:30 工作会议
* 开会讨论项目进展 #工作
* 确定下一步计划

## 20:00 日总结
* 今天完成了重要的代码重构 #good
* 学到了新的Flutter技巧 #good
* 遇到了一个难解决的bug #difficult
* 明天需要优化代码结构 #different
* 观察到团队协作更加顺畅 #observe

## 18:00 运动
* 跑步30分钟 #健康
* 感觉精力充沛
''';

  // 测试原始解析
  print('=== 原始解析结果 ===');
  // 这里需要导入 DiaryDao 来测试原始功能
  // final originalHistory = DiaryDao.parseDiaryMarkdownToChatHistory(testContent);
  // for (int i = 0; i < originalHistory.length; i++) {
  //   final item = originalHistory[i];
  //   print('$i: ${item['time']} - ${item['title']} - Summary: ${DiaryContentService.isSummaryContent(item['q'] ?? '')}');
  // }

  // 测试新的排序功能
  print('\n=== 新排序结果（总结优先）===');
  final sortedHistory = DiaryContentService.getChatHistoryWithSummaryFirst(testContent);
  for (int i = 0; i < sortedHistory.length; i++) {
    final item = sortedHistory[i];
    final isSummary = DiaryContentService.isSummaryContent(item['q'] ?? '');
    print('$i: ${item['time']} - ${item['title']} - Summary: $isSummary');
  }

  // 测试总结内容解析
  print('\n=== 总结内容解析测试 ===');
  const summaryContent = '''
* 今天完成了重要的代码重构 #good
* 学到了新的Flutter技巧 #good
* 遇到了一个难解决的bug #difficult
* 明天需要优化代码结构 #different
* 观察到团队协作更加顺畅 #observe
''';

  final parsed = DiaryContentService.parseSummaryContent(summaryContent);
  for (final group in parsed.keys) {
    if (parsed[group]!.isNotEmpty) {
      print('$group: ${parsed[group]!.length} items');
      for (final item in parsed[group]!) {
        final cleaned = DiaryContentService.cleanSummaryItemContent(item);
        print('  - $cleaned');
      }
    }
  }
}
