import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import '../util/ai_service.dart';
import '../dao/diary_dao.dart';
import '../util/llm_error_dialog.dart';
import '../diary/chat_history_service.dart';
import '../config/config_service.dart';
import '../config/language_service.dart';
import '../model/enums.dart';
import '../util/prompt_util.dart';
import '../model/prompt_constants.dart';
import '../generated/l10n/app_localizations.dart';

class DiaryChatService {
  // Load current model name
  static Future<String> loadCurrentModelName(BuildContext context) async {
    try {
      final config = await AppConfigService.load();
      return config.model.isNotEmpty ? config.model.first.model : AppLocalizations.of(context)!.noFilesFound;
    } catch (e) {
      return AppLocalizations.of(context)!.noFilesFound;
    }
  }

  // Let AI extract category and title
  static Future<Map<String, String>> extractCategoryAndTitle(
    BuildContext context,
    String question,
    String answer,
  ) async {
    try {
      final prompt = PromptConstants.getExtractCategoryAndTitlePrompt()
          .replaceAll(r'{{question}}', question)
          .replaceAll(r'{{answer}}', answer);
      final messages = [
        {'role': 'user', 'content': prompt},
      ];
      Map<String, String> result = {
        AppLocalizations.of(context)!.category: AppLocalizations.of(context)!.aiContentPlaceholder,
        AppLocalizations.of(context)!.diaryContent: '',
      };
      bool completed = false;

      await AiService.askStream(
        messages: messages,
        onDelta: (data) {},
        onDone: (data) {
          String content = data['content']?.trim() ?? '';
          try {
            // 1. Remove markdown code block wrapper
            if (content.startsWith('```')) {
              final idx = content.indexOf('```', 3);
              if (idx > 0) {
                content = content.substring(3, idx).trim();
                // Might have json tag
                if (content.startsWith('json')) {
                  content = content.substring(4).trim();
                }
              }
            }
            // 2. Trim whitespace
            content = content.trim();
            // 3. Try direct parse
            Map<String, dynamic> map = {};
            try {
              map = Map<String, dynamic>.from(jsonDecode(content));
            } catch (_) {
              // 4. If failed, try to extract first {...} part
              final start = content.indexOf('{');
              final end = content.lastIndexOf('}');
              if (start >= 0 && end > start) {
                final jsonStr = content.substring(start, end + 1);
                map = Map<String, dynamic>.from(jsonDecode(jsonStr));
              } else {
                throw Exception('No valid JSON found');
              }
            }
            // Parse the JSON response based on language
            final languageService = LanguageService.instance;
            final isZh = languageService.currentLocale.languageCode == 'zh';

            String categoryKey = isZh ? '分类' : 'Category';
            String titleKey = isZh ? '标题' : 'Title';

            if (map[categoryKey] is String && map[titleKey] is String) {
              result = {
                AppLocalizations.of(context)!.category: map[categoryKey],
                AppLocalizations.of(context)!.diaryContent: map[titleKey],
              };
            }
          } catch (e) {
            print('Failed to parse AI returned JSON: \\${data['content']}');
          }
          completed = true;
        },
        onError: (error) {
          print(AppLocalizations.of(context)!.loadingFailed);
          completed = true;
        },
      );

      while (!completed) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return result;
    } catch (e) {
      print(AppLocalizations.of(context)!.loadingFailed);
      return {
        AppLocalizations.of(context)!.category: AppLocalizations.of(context)!.aiContentPlaceholder,
        AppLocalizations.of(context)!.diaryContent: '',
      };
    }
  }

  // Auto extract category and title and save conversation to diary file
  static Future<void> extractCategoryAndSave(BuildContext context, List<Map<String, String>> history) async {
    if (history.isEmpty) return;

    try {
      print('=== extractCategoryAndSave START ===');

      // Only process the latest round of conversation (if exists)
      final lastHistory = history.last;
      if (lastHistory['q']?.isNotEmpty == true && lastHistory['a']?.isNotEmpty == true) {
        print('Processing conversation: Q="${lastHistory['q']}", A length=${lastHistory['a']?.length}');

        // Let AI extract category and title
        final result = await extractCategoryAndTitle(context, lastHistory['q']!, lastHistory['a']!);
        print('AI extraction result: $result');

        // Use correct keys for updating history
        final categoryKey = AppLocalizations.of(context)!.category;
        final titleKey = AppLocalizations.of(context)!.diaryContent;
        history[history.length - 1]['category'] = result[categoryKey] ?? '';
        history[history.length - 1]['title'] = result[titleKey] ?? ''; // This should be the extracted title

        // Save to diary file after extraction
        final content = DiaryDao.formatDiaryContent(
          context: context,
          title: history.last['title'] ?? '',
          content: history.last['q'] ?? '',
          analysis: history.last['a'] ?? '',
          category: history.last['category'] ?? '',
          time: history.last['time'],
        );

        print('Formatted diary content length: ${content.length}');
        await DiaryDao.appendToDailyDiary(content);

        // Print save path (for debug)
        final fileName = DiaryDao.getDiaryFileName();
        final diaryDir = await DiaryDao.getDiaryDir();
        final filePath = '$diaryDir/$fileName';
        print('Diary auto-appended to: $filePath, category:${history.last['category']}, title: ${history.last['title']}');

        // 验证文件是否真的被保存了
        final file = File(filePath);
        if (await file.exists()) {
          final savedContent = await file.readAsString();
          print('File saved successfully, content length: ${savedContent.length}');

          // 显示保存成功的提示
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('💾 ${AppLocalizations.of(context)!.saveSuccess}'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('File was not created after save operation');
        }
      } else {
        print('Skipping save: conversation incomplete. Q empty: ${lastHistory['q']?.isEmpty}, A empty: ${lastHistory['a']?.isEmpty}');
      }

      print('=== extractCategoryAndSave END ===');
    } catch (e) {
      print('Auto-save failed: ${e.toString()}');
      print('Stack trace: ${StackTrace.current}');

      // 显示错误信息给用户，让用户知道保存失败了
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${AppLocalizations.of(context)!.saveFailed}: ${e.toString()}'),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: '重试',
              onPressed: () => extractCategoryAndSave(context, history),
            ),
          ),
        );
      }
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

  // 处理LLM配置错误，显示用户友好的错误对话框
  static Future<void> handleLlmConfigurationError(BuildContext context, String errorMessage) async {
    if (LlmErrorDialog.isLlmConfigurationError(errorMessage)) {
      final statusCode = LlmErrorDialog.extractStatusCode(errorMessage);
      await LlmErrorDialog.showLlmConfigurationError(context, errorMessage: errorMessage, statusCode: statusCode);
    }
  }

  // 检查是否为LLM配置相关错误
  static bool isLlmConfigurationError(String errorMessage) {
    return LlmErrorDialog.isLlmConfigurationError(errorMessage);
  }

  // 显示LLM配置错误对话框
  static Future<void> showConfigurationErrorDialog(BuildContext context, dynamic error) async {
    final errorMessage = error.toString();
    if (isLlmConfigurationError(errorMessage)) {
      await handleLlmConfigurationError(context, errorMessage);
    }
  }

  // 构建聊天请求
  static Future<Map<String, dynamic>> buildChatRequest(
    BuildContext context,
    List<Map<String, String>> history,
    String userInput,
  ) async {
    final historyWindow = ChatHistoryService.getRecent(history);
    final systemPrompt = await getActivePromptContent(PromptCategory.chat);
    final messages = AiService.buildMessages(systemPrompt: systemPrompt, history: historyWindow, userInput: userInput);

    return await AiService.buildChatRequestRaw(messages: messages, stream: true);
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
    final systemPrompt = await getActivePromptContent(PromptCategory.chat);
    final messages = AiService.buildMessages(systemPrompt: systemPrompt, history: historyWindow, userInput: userInput);

    await AiService.askStream(messages: messages, onDelta: onDelta, onDone: onDone, onError: onError);
  }
}
