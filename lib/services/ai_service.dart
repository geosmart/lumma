import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'prompt_service.dart';

class AiService {
  /// 构造消息体，注入系统提示词
  static Future<List<Map<String, String>>> buildMessages({
    required List<Map<String, String>> history,
    String? systemPrompt,
    String? userInput,
  }) async {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt.trim()});
    }
    for (final h in history) {
      if (h['q'] != null && h['q']!.isNotEmpty) {
        messages.add({'role': 'assistant', 'content': h['q']!});
      }
      if (h['a'] != null && h['a']!.isNotEmpty) {
        messages.add({'role': 'user', 'content': h['a']!});
      }
    }
    if (userInput != null && userInput.isNotEmpty) {
      messages.add({'role': 'user', 'content': userInput});
    }
    return messages;
  }

  /// 普通问答（非流式）
  static Future<String> ask({
    required List<Map<String, String>> history,
    required String userInput,
  }) async {
    final configs = await ConfigService.loadModelConfigs();
    final active = configs.firstWhere((e) => e.isActive, orElse: () => configs.first);
    final url = Uri.parse('${active.baseUrl}/chat/completions');
    final systemPrompt = await PromptService.getActivePromptContent('qa');
    final messages = await buildMessages(history: history, systemPrompt: systemPrompt, userInput: userInput);
    final body = jsonEncode({
      'model': active.model,
      'messages': messages,
      'stream': false,
    });
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${active.apiKey}',
    };
    final resp = await http.post(url, body: body, headers: headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['choices'][0]['message']['content'] ?? '';
    } else {
      throw Exception('AI接口错误: ${resp.statusCode} ${resp.body}');
    }
  }

  /// 流式问答
  static Future<void> askStream({
    required List<Map<String, String>> history,
    required String userInput,
    required void Function(String) onDelta,
    required void Function(String) onDone,
    required void Function(Object error)? onError,
  }) async {
    final configs = await ConfigService.loadModelConfigs();
    final active = configs.firstWhere((e) => e.isActive, orElse: () => configs.first);
    final url = Uri.parse('${active.baseUrl}/chat/completions');
    final systemPrompt = await PromptService.getActivePromptContent('qa');
    final messages = await buildMessages(history: history, systemPrompt: systemPrompt, userInput: userInput);
    final body = jsonEncode({
      'model': active.model,
      'messages': messages,
      'stream': true,
    });
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${active.apiKey}',
    };
    try {
      final req = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;
      final resp = await req.send();
      if (resp.statusCode == 200) {
        String buffer = '';
        await for (final chunk in resp.stream.transform(utf8.decoder)) {
          for (final line in const LineSplitter().convert(chunk)) {
            if (line.startsWith('data:')) {
              final data = line.substring(5).trim();
              if (data == '[DONE]') {
                onDone(buffer);
                return;
              }
              if (data.isNotEmpty) {
                try {
                  final jsonData = jsonDecode(data);
                  final delta = jsonData['choices'][0]['delta']['content'] ?? '';
                  if (delta.isNotEmpty) {
                    buffer += delta;
                    onDelta(buffer);
                  }
                } catch (e) {
                  onError?.call('FormatException: $e\n原始内容: $data');
                }
              }
            }
          }
        }
      } else {
        onError?.call(Exception('AI接口错误: ${resp.statusCode}'));
      }
    } catch (e) {
      onError?.call(e);
    }
  }

  /// 问答总结流式接口，兼容 DiaryQaPage
  static Future<void> summaryWithPromptStream({
    required List<String> questions,
    required List<String> answers,
    required void Function(String) onDelta,
    required void Function(String) onDone,
    required void Function(Object error)? onError,
  }) async {
    final systemPrompt = await PromptService.getActivePromptContent('qa');
    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt.trim()});
    }
    for (int i = 0; i < answers.length; i++) {
      messages.add({'role': 'user', 'content': 'Q${i + 1}: ${questions[i]}\nA: ${answers[i]}'});
    }
    messages.add({'role': 'user', 'content': '请根据以上内容总结生成一篇markdown日记'});
    await askStream(
      history: messages,
      userInput: '',
      onDelta: onDelta,
      onDone: onDone,
      onError: onError,
    );
  }

  /// 构造大模型 chat 请求原始数据（url、headers、body），用于调试/生成CURL
  static Future<Map<String, dynamic>> buildChatRequestRaw({
    required List<Map<String, String>> history,
    required String userInput,
    bool stream = true,
    bool injectSystemPrompt = true,
  }) async {
    final activeConfigs = await ConfigService.loadModelConfigs();
    final active = activeConfigs.firstWhere((e) => e.isActive, orElse: () => activeConfigs.first);
    final url = Uri.parse('${active.baseUrl}/chat/completions');
    final systemPrompt = await PromptService.getActivePromptContent('qa');
    final messages = <Map<String, String>>[];
    if (injectSystemPrompt && systemPrompt != null && systemPrompt.trim().isNotEmpty && history.isEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt.trim()});
    }
    for (final h in history) {
      if (h['q'] != null && h['q']!.isNotEmpty) {
        messages.add({'role': 'user', 'content': h['q']!});
      }
      if (h['a'] != null && h['a']!.isNotEmpty) {
        messages.add({'role': 'assistant', 'content': h['a']!});
      }
    }
    if (userInput.isNotEmpty) {
      messages.add({'role': 'user', 'content': userInput});
    }
    final body = {
      'model': active.model,
      'messages': messages,
      'stream': stream,
    };
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${active.apiKey}',
    };
    return {
      'url': url.toString(),
      'headers': headers,
      'body': body,
    };
  }
}
