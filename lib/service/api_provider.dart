import 'dart:async';
import 'package:get/get.dart';
import 'package:lumma/service/config_service.dart';

/// GetX 网络请求服务提供者
class ApiProvider extends GetConnect {
  @override
  void onInit() {
    super.onInit();

    // 配置超时时间
    timeout = const Duration(seconds: 30);

    // 配置请求拦截器
    httpClient.addRequestModifier<dynamic>((request) async {
      // 可以在这里添加通用请求头
      request.headers['Content-Type'] = 'application/json';
      return request;
    });

    // 配置响应拦截器
    httpClient.addResponseModifier<dynamic>((request, response) {
      // 可以在这里处理通用响应
      return response;
    });
  }

  /// 通用 GET 请求
  Future<Response> getRequest(String url, {Map<String, String>? headers}) async {
    try {
      final response = await get(url, headers: headers);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 通用 POST 请求
  Future<Response> postRequest(String url, dynamic body, {Map<String, String>? headers}) async {
    try {
      final response = await post(url, body, headers: headers);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 通用 PUT 请求
  Future<Response> putRequest(String url, dynamic body, {Map<String, String>? headers}) async {
    try {
      final response = await put(url, body, headers: headers);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 通用 DELETE 请求
  Future<Response> deleteRequest(String url, {Map<String, String>? headers}) async {
    try {
      final response = await delete(url, headers: headers);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

/// AI 服务 - 使用 GetConnect
class AiApiService extends GetConnect {
  @override
  void onInit() {
    super.onInit();
    timeout = const Duration(minutes: 2);
  }

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
    if (history.isNotEmpty && history.first.containsKey('role') && history.first.containsKey('content')) {
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

  /// 流式问答 - 使用原有的 http 包实现，因为 GetConnect 对流式响应支持有限
  /// 这里保持原有实现，只是包装在 GetX 服务中
  static Future<void> askStream({
    required List<Map<String, String>> messages,
    required void Function(Map<String, String>) onDelta,
    required void Function(Map<String, String>) onDone,
    required void Function(Object error)? onError,
  }) async {
    // 保持原有的 ai_service.dart 中的实现
    // 这里只是一个占位，实际实现应该从原 AiService 复制过来
    // 因为 GetConnect 对流式响应的支持有限，建议保留原有的 http 包实现
    try {
      final appConfig = await AppConfigService.load();
      final configs = appConfig.model;
      if (configs.isEmpty) {
        onError?.call(Exception('没有可用的大模型配置，请先配置大模型服务'));
        return;
      }
      // ... 其他实现
    } catch (e) {
      onError?.call(e);
    }
  }

  /// 非流式问答
  Future<Response> ask(List<Map<String, String>> messages) async {
    try {
      final appConfig = await AppConfigService.load();
      final configs = appConfig.model;
      if (configs.isEmpty) {
        throw Exception('没有可用的大模型配置');
      }
      final active = configs.firstWhere((e) => e.active, orElse: () => configs.first);

      final url = '${active.baseUrl}/chat/completions';
      final body = {
        'model': active.model,
        'messages': messages,
        'stream': false,
      };
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${active.apiKey}',
      };

      final response = await post(url, body, headers: headers);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
