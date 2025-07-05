import 'dart:convert';
import '../util/ai_service.dart';
import '../util/markdown_service.dart';
import '../diary/chat_history_service.dart';
import '../config/config_service.dart';
import '../model/enums.dart';
import '../util/prompt_util.dart';
import '../model/prompt_constants.dart';
import '../dao/diary_dao.dart';

class DiaryChatService {
  // 加载当前模型名称
  static Future<String> loadCurrentModelName() async {
    try {
      final config = await AppConfigService.load();
      return config.model.isNotEmpty ? config.model.first.model : '未知模型';
    } catch (e) {
      return '未知模型';
    }
  }

  // 让AI提取分类和标题
  static Future<Map<String, String>> extractCategoryAndTitle(String question, String answer) async {
    try {
      final prompt = PromptConstants.extractCategoryAndTitlePrompt
        .replaceAll(r'{{question}}', question)
        .replaceAll(r'{{answer}}', answer);
      final messages = [
        {'role': 'user', 'content': prompt}
      ];
      Map<String, String> result = {'分类': '想法', '标题': ''};
      bool completed = false;

      await AiService.askStream(
        messages: messages,
        onDelta: (data) {},
        onDone: (data) {
          String content = data['content']?.trim() ?? '';
          try {
            // 1. 去除markdown代码块包裹
            if (content.startsWith('```')) {
              final idx = content.indexOf('```', 3);
              if (idx > 0) {
                content = content.substring(3, idx).trim();
                // 可能有json标记
                if (content.startsWith('json')) {
                  content = content.substring(4).trim();
                }
              }
            }
            // 2. 去除前后空白
            content = content.trim();
            // 3. 尝试直接解析
            Map<String, dynamic> map = {};
            try {
              map = Map<String, dynamic>.from(jsonDecode(content));
            } catch (_) {
              // 4. 若失败，尝试提取第一个{...}部分
              final start = content.indexOf('{');
              final end = content.lastIndexOf('}');
              if (start >= 0 && end > start) {
                final jsonStr = content.substring(start, end + 1);
                map = Map<String, dynamic>.from(jsonDecode(jsonStr));
              } else {
                throw Exception('未找到有效JSON');
              }
            }
            if (map['分类'] is String && map['标题'] is String) {
              result = {'分类': map['分类'], '标题': map['标题']};
            }
          } catch (e) {
            print('解析AI返回JSON失败: ${data['content']}');
          }
          completed = true;
        },
        onError: (error) {
          print('提取分类和标题失败: ${error.toString()}');
          completed = true;
        },
      );

      while (!completed) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return result;
    } catch (e) {
      print('提取分类和标题失败: ${e.toString()}');
      return {'分类': '想法', '标题': ''};
    }
  }

  // 自动提取分类和标题并保存对话到日记文件
  static Future<void> extractCategoryAndSave(List<Map<String, String>> history) async {
    if (history.isEmpty) return;

    try {
      // 只处理最新的一轮对话（如果存在）
      final lastHistory = history.last;
      if (lastHistory['q']?.isNotEmpty == true && lastHistory['a']?.isNotEmpty == true) {
        // 让AI提取分类和标题
        final result = await extractCategoryAndTitle(lastHistory['q']!, lastHistory['a']!);

        // 更新历史记录
        history[history.length - 1]['category'] = result['分类'] ?? '想法';
        history[history.length - 1]['title'] = result['标题'] ?? '';

        // 分类和标题提取完成后，保存到日记文件
        final content = DiaryDao.formatDiaryContent(
          title: history.last['title'] ?? '',
          content: history.last['q'] ?? '',
          analysis: history.last['a'] ?? '',
          category: history.last['category'] ?? '',
          time: history.last['time'],
        );
        await MarkdownService.appendToDailyDiary(content);

        // 打印保存路径（调试用）
        final fileName = MarkdownService.getDiaryFileName();
        final diaryDir = await MarkdownService.getDiaryDir();
        final filePath = '$diaryDir/$fileName';
        print('日记已自动追加到: $filePath，分类: \u001b[32m${result['分类']}\u001b[0m，标题: \u001b[34m${result['标题']}\u001b[0m');
      }
    } catch (e) {
      print('自动保存失败: \u001b[31m${e.toString()}\u001b[0m');
      // 不显示错误提示，避免影响用户体验
    }
  }

  // 检查API返回的错误信息
  static String? checkApiError(Map<String, dynamic> data) {
    try {
      if (data['content'] != null && data['content']!.trim().startsWith('{')) {
        final errJson = jsonDecode(data['content']!);
        if (errJson is Map && errJson['error'] != null && errJson['error']['message'] != null) {
          return 'AI接口错误: ${errJson['error']['message']}';
        }
      }
    } catch (_) {}
    return null;
  }

  // 解析错误信息
  static String parseErrorMessage(dynamic err) {
    String errorMsg = 'AI接口错误: $err';
    // 检查是否为API返回的JSON错误
    try {
      if (err is String && err.trim().startsWith('{')) {
        final errJson = jsonDecode(err);
        if (errJson is Map && errJson['error'] != null && errJson['error']['message'] != null) {
          errorMsg = 'AI接口错误: ${errJson['error']['message']}';
        }
      }
    } catch (_) {}
    return errorMsg;
  }

  // 构建聊天请求
  static Future<Map<String, dynamic>> buildChatRequest(List<Map<String, String>> history, String userInput) async {
    final historyWindow = ChatHistoryService.getRecent(history);
    final systemPrompt = await getActivePromptContent(PromptCategory.qa);
    final messages = AiService.buildMessages(
      systemPrompt: systemPrompt,
      history: historyWindow,
      userInput: userInput,
    );

    return await AiService.buildChatRequestRaw(
      messages: messages,
      stream: true,
    );
  }

  // 格式化请求JSON用于调试
  static String formatRequestJson(Map<String, dynamic> raw) {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(raw);
    return prettyJson; // 直接返回格式化的JSON，不包装在markdown代码块中
  }

  // 发送AI请求
  static Future<void> sendAiRequest({
    required List<Map<String, String>> history,
    required String userInput,
    required Function(Map<String, dynamic>) onDelta,
    required Function(Map<String, dynamic>) onDone,
    required Function(dynamic) onError,
  }) async {
    final historyWindow = ChatHistoryService.getRecent(history);
    final systemPrompt = await getActivePromptContent(PromptCategory.qa);
    final messages = AiService.buildMessages(
      systemPrompt: systemPrompt,
      history: historyWindow,
      userInput: userInput,
    );

    await AiService.askStream(
      messages: messages,
      onDelta: onDelta,
      onDone: onDone,
      onError: onError,
    );
  }
}
