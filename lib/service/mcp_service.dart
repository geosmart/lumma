import 'package:get/get.dart';
import '../model/mcp_config.dart';
import 'api_provider.dart';
import 'config_service.dart' show AppConfigService;

class McpService {
  static final ApiProvider _apiProvider = Get.find<ApiProvider>();

  /// 持久化日记到MCP服务器
  static Future<bool> persistDiary({
    required String entityId,
    required String content,
    required int createTime,
  }) async {
    print('[MCP Service] persistDiary被调用');
    print('[MCP Service] entityId: $entityId');
    print('[MCP Service] content长度: ${content.length}');
    print('[MCP Service] createTime: $createTime');

    try {
      final config = await _getMcpConfig();

      print('[MCP Service] 获取到配置: enabled=${config.enabled}, url=${config.url}');

      // 检查配置是否完整
      if (!config.isConfigured) {
        print('[MCP Service] 配置未完成，跳过同步');
        return false;
      }

      // 构建请求体
      final requestBody = {
        'method': 'tools/call',
        'params': {
          'name': 'persist_diary',
          'arguments': {
            'entityId': entityId,
            'content': content,
            'createTime': createTime.toString(),
          },
        },
        'jsonrpc': '2.0',
      };

      print('[MCP Service] 请求体: $requestBody');

      // 发送请求
      final headers = {
        'Authorization': 'Bearer ${config.token}',
        'Content-Type': 'application/json',
      };

      print('[MCP Service] 发送POST请求到: ${config.url}');

      final response = await _apiProvider.postRequest(
        config.url,
        requestBody,
        headers: headers,
      );

      print('[MCP Service] 响应状态码: ${response.statusCode}');
      print('[MCP Service] 响应内容: ${response.bodyString}');

      // 检查响应
      if (response.statusCode == 200) {
        print('[MCP Service] 日记保存成功: $entityId');
        return true;
      } else {
        print('[MCP Service] 日记保存失败: ${response.statusCode}');
        return false;
      }
    } catch (e, stackTrace) {
      print('[MCP Service] 日记保存异常: $e');
      print('[MCP Service] Stack trace: $stackTrace');
      return false;
    }
  }

  /// 获取MCP配置
  static Future<McpConfig> _getMcpConfig() async {
    final appConfig = await AppConfigService.load();
    return appConfig.mcp;
  }

  /// 测试MCP连接
  static Future<Map<String, dynamic>> testConnection({
    required String url,
    required String token,
    required String entityId,
  }) async {
    try {
      final requestBody = {
        'method': 'tools/call',
        'params': {
          'name': 'persist_diary',
          'arguments': {
            'entityId': entityId,
            'content': '测试连接',
            'createTime': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        },
        'jsonrpc': '2.0',
      };

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await _apiProvider.postRequest(
        url,
        requestBody,
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': '连接成功',
          'response': response.bodyString,
        };
      } else {
        return {
          'success': false,
          'message': '连接失败: ${response.statusCode}',
          'response': response.bodyString,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '连接异常: $e',
      };
    }
  }
}
