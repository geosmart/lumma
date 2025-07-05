import 'package:flutter/material.dart';
import 'dart:io';
import '../util/markdown_service.dart';
import '../dao/diary_dao.dart';

/// 日记内容服务类，处理日记内容的业务逻辑
class DiaryContentService {
  /// 加载日记内容
  static Future<Map<String, dynamic>> loadDiaryContent(String fileName) async {
    final diaryDir = await MarkdownService.getDiaryDir();
    final file = File('$diaryDir/$fileName');
    final content = await MarkdownService.readDiaryMarkdown(file);

    // 解析 frontmatter
    Map<String, String>? frontmatter;
    String body = content;
    if (content.startsWith('---')) {
      final lines = content.split('\n');
      final endIdx = lines.indexWhere((l) => l.trim() == '---', 1);
      if (endIdx > 0) {
        frontmatter = {};
        for (var i = 1; i < endIdx; i++) {
          final line = lines[i];
          final idx = line.indexOf(':');
          if (idx > 0) {
            final key = line.substring(0, idx).trim();
            final value = line.substring(idx + 1).trim();
            frontmatter[key] = value;
          }
        }
        // 去除 frontmatter 部分
        body = lines.sublist(endIdx + 1).join('\n');
      }
    }

    return {
      'content': body,
      'fullContent': content,
      'frontmatter': frontmatter,
      'filePath': file.path,
    };
  }

  /// 保存日记内容
  static Future<void> saveDiaryContent(String content, String fileName) async {
    await MarkdownService.saveDiaryMarkdown(content, fileName: fileName);
  }

  /// 获取聊天历史记录并排序，将总结内容放在最前面
  static List<Map<String, String>> getChatHistoryWithSummaryFirst(String content) {
    final history = DiaryDao.parseDiaryMarkdownToChatHistory(content);

    // 分离总结内容和普通内容
    final summaryItems = <Map<String, String>>[];
    final normalItems = <Map<String, String>>[];

    for (final item in history) {
      if (isSummaryContent(item['q'] ?? '') || isSummaryContent(item['a'] ?? '')) {
        summaryItems.add(item);
      } else {
        normalItems.add(item);
      }
    }

    // 总结内容放在最前面
    return [...summaryItems, ...normalItems];
  }

  /// 判断是否为日总结内容
  static bool isSummaryContent(String content) {
    // 如果内容包含日总结相关的标签组合，则认为是日总结内容
    final hasObserve = content.contains('#observe');
    final hasGood = content.contains('#good');
    final hasDifficult = content.contains('#difficult');
    final hasDifferent = content.contains('#different');

    // 如果包含至少2个主要分类标签，则认为是日总结内容
    final count = [hasObserve, hasGood, hasDifficult, hasDifferent].where((x) => x).length;
    return count >= 2;
  }

  /// 判断是否应该显示时间和标题（日总结时不显示）
  static bool shouldShowTimeAndTitle(Map<String, String> historyItem) {
    final q = historyItem['q'] ?? '';
    final a = historyItem['a'] ?? '';
    return !isSummaryContent(q) && !isSummaryContent(a);
  }

  /// 根据标签类型返回对应的颜色配置
  static Map<String, Color> getCategoryColors(String category) {
    final lowerCategory = category.toLowerCase();

    // 观察类标签 - 蓝色系
    if (lowerCategory.contains('observe') || lowerCategory.contains('观察') ||
        lowerCategory.contains('环境') || lowerCategory.contains('他人')) {
      return {
        'background': Colors.blue[50]!,
        'border': Colors.blue[200]!,
        'text': Colors.blue[700]!,
      };
    }

    // 积极/好事类标签 - 绿色系
    if (lowerCategory.contains('good') || lowerCategory.contains('成就') ||
        lowerCategory.contains('喜悦') || lowerCategory.contains('感恩')) {
      return {
        'background': Colors.green[50]!,
        'border': Colors.green[200]!,
        'text': Colors.green[700]!,
      };
    }

    // 困难/挑战类标签 - 红色系
    if (lowerCategory.contains('difficult') || lowerCategory.contains('挑战') ||
        lowerCategory.contains('情绪') || lowerCategory.contains('身体')) {
      return {
        'background': Colors.red[50]!,
        'border': Colors.red[200]!,
        'text': Colors.red[700]!,
      };
    }

    // 改进/不同类标签 - 紫色系
    if (lowerCategory.contains('different') || lowerCategory.contains('觉察') ||
        lowerCategory.contains('改进')) {
      return {
        'background': Colors.purple[50]!,
        'border': Colors.purple[200]!,
        'text': Colors.purple[700]!,
      };
    }

    // 日总结 - 橙色系（特别处理）
    if (lowerCategory.contains('日总结') || lowerCategory.contains('总结') ||
        lowerCategory == '## 日总结') {
      return {
        'background': Colors.orange[50]!,
        'border': Colors.orange[200]!,
        'text': Colors.orange[700]!,
      };
    }

    // 工作相关 - 靛蓝色系
    if (lowerCategory.contains('工作') || lowerCategory.contains('职场') ||
        lowerCategory.contains('meeting') || lowerCategory.contains('项目')) {
      return {
        'background': Colors.indigo[50]!,
        'border': Colors.indigo[200]!,
        'text': Colors.indigo[700]!,
      };
    }

    // 生活相关 - 棕色系
    if (lowerCategory.contains('生活') || lowerCategory.contains('日常') ||
        lowerCategory.contains('家庭') || lowerCategory.contains('休闲')) {
      return {
        'background': Colors.brown[50]!,
        'border': Colors.brown[200]!,
        'text': Colors.brown[700]!,
      };
    }

    // 学习相关 - 深紫色系
    if (lowerCategory.contains('学习') || lowerCategory.contains('读书') ||
        lowerCategory.contains('知识') || lowerCategory.contains('技能')) {
      return {
        'background': Colors.deepPurple[50]!,
        'border': Colors.deepPurple[200]!,
        'text': Colors.deepPurple[700]!,
      };
    }

    // 健康相关 - 粉红色系
    if (lowerCategory.contains('健康') || lowerCategory.contains('运动') ||
        lowerCategory.contains('饮食') || lowerCategory.contains('锻炼')) {
      return {
        'background': Colors.pink[50]!,
        'border': Colors.pink[200]!,
        'text': Colors.pink[700]!,
      };
    }

    // 其他标签 - 默认青色系
    return {
      'background': Colors.teal[50]!,
      'border': Colors.teal[200]!,
      'text': Colors.teal[700]!,
    };
  }

  /// 解析日总结内容并按分组返回
  static Map<String, List<String>> parseSummaryContent(String content) {
    // 按4个大类分组
    final Map<String, List<String>> groupedContent = {
      'observe': [],
      'good': [],
      'difficult': [],
      'different': [],
    };

    // 解析内容并分组
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;

      if (trimmedLine.contains('#observe')) {
        groupedContent['observe']!.add(trimmedLine);
      } else if (trimmedLine.contains('#good')) {
        groupedContent['good']!.add(trimmedLine);
      } else if (trimmedLine.contains('#difficult')) {
        groupedContent['difficult']!.add(trimmedLine);
      } else if (trimmedLine.contains('#different')) {
        groupedContent['different']!.add(trimmedLine);
      }
    }

    return groupedContent;
  }

  /// 获取总结分组信息
  static Map<String, Map<String, dynamic>> getSummaryGroupInfo() {
    return {
      'observe': {'title': '观察发现', 'icon': Icons.visibility, 'color': Colors.blue},
      'good': {'title': '积极收获', 'icon': Icons.favorite, 'color': Colors.green},
      'difficult': {'title': '困难挑战', 'icon': Icons.warning, 'color': Colors.red},
      'different': {'title': '反思改进', 'icon': Icons.psychology, 'color': Colors.purple},
    };
  }

  /// 清理总结项内容（去除标签和标记）
  static String cleanSummaryItemContent(String content) {
    final tagRegex = RegExp(r'(#[^\s#]+)');

    // 去掉所有标签，只显示纯文本内容
    final cleanContent = content.replaceAll(tagRegex, '').trim();

    // 去掉开头的 * 或 - 标记
    final finalContent = cleanContent.replaceFirst(RegExp(r'^[\*\-]\s*'), '');

    return finalContent;
  }

  /// 解析内容中的标签
  static bool hasTagsInContent(String content) {
    final tagRegex = RegExp(r'(#[^\s#]+)');
    return tagRegex.hasMatch(content);
  }

  /// 获取内容中的标签匹配
  static Iterable<RegExpMatch> getTagMatches(String content) {
    final tagRegex = RegExp(r'(#[^\s#]+)');
    return tagRegex.allMatches(content);
  }
}
