import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config_service.dart';
import '../util/prompt_util.dart';
import '../model/enums.dart';

class AiService {
  /// 构造消息体
  static List<Map<String, String>> buildMessages({
    String? systemPrompt,
    required List<Map<String, String>> history,
    String? userInput,
  }) {
    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt.trim()});
    }
    // 兼容 q/a 结构和 role/content 结构
    if (history.isNotEmpty &&
        history.first.containsKey('role') &&
        history.first.containsKey('content')) {
      messages.addAll(history);
    } else {
      for (final h in history) {
        if (h['q'] != null && h['q']!.isNotEmpty) {
          messages.add({'role': 'user', 'content': h['q']!});
        }
        if (h['a'] != null && h['a']!.isNotEmpty) {
          messages.add({'role': 'assistant', 'content': h['a']!});
        }
      }
    }
    if (userInput != null && userInput.isNotEmpty) {
      messages.add({'role': 'user', 'content': userInput});
    }
    return messages;
  }

  /// 流式问答
  static Future<void> askStream({
    required List<Map<String, String>> messages,
    required void Function(Map<String, String>) onDelta,
    required void Function(Map<String, String>) onDone,
    required void Function(Object error)? onError,
  }) async {
    final appConfig = await AppConfigService.load();
    final configs = appConfig.model;
    if (configs.isEmpty) {
      onError?.call(Exception('没有可用的大模型配置，请先配置大模型服务'));
      return;
    }
    final active = configs.firstWhere((e) => e.active, orElse: () => configs.first);

    // 验证配置完整性
    if (active.baseUrl.isEmpty) {
      onError?.call(Exception('大模型服务地址未配置，请检查配置'));
      return;
    }
    if (active.apiKey.isEmpty) {
      onError?.call(Exception('大模型API密钥未配置，请检查配置'));
      return;
    }
    if (active.model.isEmpty) {
      onError?.call(Exception('大模型名称未配置，请检查配置'));
      return;
    }

    final url = Uri.parse('${active.baseUrl}/chat/completions');
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
      final request = http.Request('POST', url)
        ..headers.addAll(headers)
        ..body = body;

      print('[AI-DEBUG] Request: POST $url');
      print('[AI-DEBUG] Headers: $headers');
      print('[AI-DEBUG] Body: $body');

      final client = http.Client();
      final fullResponse = StringBuffer();
      final fullReasoning = StringBuffer(); // 用于累加reasoning内容
      String buffer = '';
      String? reasoning;

      client.send(request).then((streamedResponse) {
        // 检查HTTP状态码
        if (streamedResponse.statusCode != 200) {
          print('[AI-ERROR] HTTP错误: ${streamedResponse.statusCode}');
          String errorMessage = '大模型服务响应错误 (${streamedResponse.statusCode})';
          if (streamedResponse.statusCode == 401) {
            errorMessage = '大模型API密钥无效，请检查配置';
          } else if (streamedResponse.statusCode == 403) {
            errorMessage = '大模型API访问被拒绝，请检查配置';
          } else if (streamedResponse.statusCode == 404) {
            errorMessage = '大模型服务地址不存在，请检查配置';
          } else if (streamedResponse.statusCode >= 500) {
            errorMessage = '大模型服务器内部错误，请稍后重试或检查配置';
          }
          onError?.call(Exception(errorMessage));
          return;
        }
        streamedResponse.stream.transform(utf8.decoder).listen(
          (chunk) {
            buffer += chunk;
            while (true) {
              final dataPrefix = 'data: ';
              final dataIndex = buffer.indexOf(dataPrefix);
              if (dataIndex == -1) {
                break;
              }

              final jsonEndIndex = buffer.indexOf('\n\n', dataIndex);
              if (jsonEndIndex == -1) {
                break;
              }

              final jsonString = buffer.substring(dataIndex + dataPrefix.length, jsonEndIndex).trim();              if (jsonString.startsWith('[DONE]')) {
                print('[AI-STREAM] Stream finished with [DONE]');
              } else if (jsonString.isNotEmpty) {
                try {
                  final data = jsonDecode(jsonString);

                  if (data['choices'] != null && data['choices'].isNotEmpty) {
                    final choice = data['choices'][0];
                    print('[AI-STREAM] Choice data: $choice');

                    final delta = choice['delta'];
                    final message = choice['message'];
                    String? content;

                    if (delta != null && delta['content'] != null) {
                      content = delta['content'] as String;
                      fullResponse.write(content);
                      print('[AI-STREAM] Delta content: $content');
                    }                    // 检查reasoning字段（可能在delta或message中）
                    if (delta != null) {
                      print('[AI-STREAM] Delta keys: ${delta.keys.toList()}');
                      if (delta['reasoning'] != null) {
                        final deltaReasoning = delta['reasoning'] as String;
                        fullReasoning.write(deltaReasoning); // 累加reasoning内容
                        reasoning = fullReasoning.toString();
                        print('[AI-STREAM] Delta reasoning: $deltaReasoning');
                        print('[AI-STREAM] Full reasoning so far: $reasoning');
                      }
                      // 检查其他可能的reasoning字段名
                      if (delta['thoughts'] != null) {
                        final deltaThoughts = delta['thoughts'] as String;
                        fullReasoning.write(deltaThoughts);
                        reasoning = fullReasoning.toString();
                        print('[AI-STREAM] Delta thoughts: $deltaThoughts');
                        print('[AI-STREAM] Full reasoning so far: $reasoning');
                      }
                      if (delta['thinking'] != null) {
                        final deltaThinking = delta['thinking'] as String;
                        fullReasoning.write(deltaThinking);
                        reasoning = fullReasoning.toString();
                        print('[AI-STREAM] Delta thinking: $deltaThinking');
                        print('[AI-STREAM] Full reasoning so far: $reasoning');
                      }
                    }
                    if (message != null) {
                      print('[AI-STREAM] Message keys: ${message.keys.toList()}');
                      if (message['reasoning'] != null) {
                        reasoning = message['reasoning'] as String;
                        print('[AI-STREAM] Message reasoning: $reasoning');
                      }
                      // 检查其他可能的reasoning字段名
                      if (message['thoughts'] != null) {
                        reasoning = message['thoughts'] as String;
                        print('[AI-STREAM] Message thoughts: $reasoning');
                      }
                      if (message['thinking'] != null) {
                        reasoning = message['thinking'] as String;
                        print('[AI-STREAM] Message thinking: $reasoning');
                      }
                    }

                    // 也检查choice级别的reasoning字段
                    if (choice['reasoning'] != null) {
                      reasoning = choice['reasoning'] as String;
                      print('[AI-STREAM] Choice reasoning: $reasoning');
                    }

                    if (content != null || reasoning != null) {
                      final deltaData = {
                        'content': fullResponse.toString(),
                        if (reasoning != null) 'reasoning': reasoning!,
                      };
                      print('[AI-STREAM] Calling onDelta with: $deltaData');
                      onDelta(deltaData);
                    }
                  }
                } catch (e) {
                  print('[AI-WARN] JSON parsing failed for chunk: $jsonString. Error: $e');
                }
              }

              buffer = buffer.substring(jsonEndIndex + 2);
            }
          },
          onDone: () {
            // 确保使用完整的reasoning内容
            final finalReasoning = fullReasoning.toString().isNotEmpty ? fullReasoning.toString() : reasoning;
            print('[AI-STREAM] Final Output: content=${fullResponse.toString()}, reasoning=$finalReasoning');
            final finalData = {
              'content': fullResponse.toString(),
              if (finalReasoning != null && finalReasoning.isNotEmpty) 'reasoning': finalReasoning,
            };
            print('[AI-STREAM] Calling onDone with: $finalData');
            onDone(finalData);
          },
          onError: (error) {
            print('[AI-ERROR] 流式响应处理异常: $error');
            String errorMessage = '大模型响应处理失败';
            if (error.toString().contains('Connection') ||
                error.toString().contains('timeout') ||
                error.toString().contains('refused')) {
              errorMessage = '无法连接到大模型服务，请检查网络连接和服务地址配置';
            } else if (error.toString().contains('certificate') ||
                      error.toString().contains('SSL') ||
                      error.toString().contains('TLS')) {
              errorMessage = '大模型服务SSL证书验证失败，请检查服务配置';
            }
            onError?.call(Exception(errorMessage));
          },
          cancelOnError: true,
        );
      }).catchError((error) {
        print('[AI-ERROR] 请求发送异常: $error');
        String errorMessage = '大模型请求发送失败';
        if (error.toString().contains('Connection') ||
            error.toString().contains('timeout') ||
            error.toString().contains('refused')) {
          errorMessage = '无法连接到大模型服务，请检查网络连接和服务地址配置';
        } else if (error.toString().contains('certificate') ||
                  error.toString().contains('SSL') ||
                  error.toString().contains('TLS')) {
          errorMessage = '大模型服务SSL证书验证失败，请检查服务配置';
        } else if (error.toString().contains('format')) {
          errorMessage = '大模型服务地址格式错误，请检查配置';
        }
        onError?.call(Exception(errorMessage));
      });
    } catch (e) {
      print('[AI-ERROR] Request exception: $e');
      String errorMessage = '大模型服务调用异常';
      if (e.toString().contains('Uri') || e.toString().contains('format')) {
        errorMessage = '大模型服务地址格式错误，请检查配置';
      } else if (e.toString().contains('encode') || e.toString().contains('json')) {
        errorMessage = '请求参数编码异常，请检查配置';
      }
      onError?.call(Exception(errorMessage));
    }
  }

  /// 使用指定类型的提示词处理文本 - 流式
  static Future<void> processTextStream({
    required String content,
    required String promptType,
    required void Function(String) onDelta,
    required void Function(String) onDone,
    required void Function(Object error)? onError,
  }) async {
    try {
      final promptCategory = PromptCategory.values.firstWhere(
        (e) => promptCategoryToString(e) == promptType,
        orElse: () => PromptCategory.chat,
      );
      final systemPrompt = await getActivePromptContent(promptCategory);
      final messages = buildMessages(
        systemPrompt: systemPrompt,
        history: [],
        userInput: content,
      );

      await askStream(
        messages: messages,
        onDelta: (data) => onDelta(data['content'] ?? ''),
        onDone: (data) => onDone(data['content'] ?? ''),
        onError: (error) {
          print('[AI-ERROR] 文本处理流异常: $error');
          String errorMessage = '文本处理失败';
          if (error.toString().contains('模型配置') ||
              error.toString().contains('API') ||
              error.toString().contains('连接') ||
              error.toString().contains('配置')) {
            errorMessage = error.toString();
          } else {
            errorMessage = '大模型处理文本时发生异常，请检查大模型配置';
          }
          onError?.call(Exception(errorMessage));
        },
      );
    } catch (e) {
      print('[AI-ERROR] 文本处理异常: $e');
      String errorMessage = '文本处理初始化失败';
      if (e.toString().contains('prompt') || e.toString().contains('Prompt')) {
        errorMessage = '提示词配置异常，请检查配置';
      } else {
        errorMessage = '大模型文本处理异常，请检查大模型配置';
      }
      onError?.call(Exception(errorMessage));
    }
  }

  /// 构造大模型 chat 请求原始数据（url、headers、body），用于调试/生成CURL
  static Future<Map<String, dynamic>> buildChatRequestRaw({
    required List<Map<String, String>> messages,
    bool stream = true,
  }) async {
    try {
      final appConfig = await AppConfigService.load();
      final configs = appConfig.model;
      if (configs.isEmpty) {
        throw Exception('没有可用的大模型配置，请先配置大模型服务');
      }
      final active = configs.firstWhere((e) => e.active,
          orElse: () => configs.first);

      // 验证配置完整性
      if (active.baseUrl.isEmpty) {
        throw Exception('大模型服务地址未配置，请检查配置');
      }
      if (active.apiKey.isEmpty) {
        throw Exception('大模型API密钥未配置，请检查配置');
      }
      if (active.model.isEmpty) {
        throw Exception('大模型名称未配置，请检查配置');
      }

      final url = Uri.parse('${active.baseUrl}/chat/completions');

      final body = {
        'model': active.model,
        'messages': messages,
        'stream': stream,
      };
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${active.apiKey}',
      };
      // 日志打印
      print('[AI-DEBUG] 请求参数: ${jsonEncode(body)}');
      return {
        'url': url.toString(),
        'headers': headers,
        'body': body,
      };
    } catch (e) {
      print('[AI-ERROR] 构造请求参数异常: $e');
      rethrow;
    }
  }
}
