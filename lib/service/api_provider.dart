import 'dart:async';
import 'package:get/get.dart';

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
