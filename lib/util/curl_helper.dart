/// curl_helper.dart
/// 提供 curl 命令生成与相关工具跳转功能
library;
import 'dart:convert';

class CurlHelper {
  /// 生成可执行的 curl 命令，headers 只保留 Authorization 和 Content-Type
  static String buildCurl(Map<String, dynamic> raw) {
    final url = raw['url'] ?? '';
    final headers = raw['headers'] as Map<String, dynamic>? ?? {};
    final body = JsonEncoder.withIndent('  ').convert(raw['body']);
    final headerStr = headers.entries
        .where((e) => e.key.toLowerCase() == 'authorization' || e.key.toLowerCase() == 'content-type')
        .map((e) => "  -H '${e.key}: ${e.value}' ").join(' \\n');
    // 多行拼接 curl
    return [
      'curl -X POST \\',
      if (headerStr.isNotEmpty) '$headerStr\\n',
      "  -d '$body' \\",
      "  '$url'"
    ].join('\n');
  }

  /// 生成 curlconverter.com 的跳转 URL
  static String? buildCurlUrl(String curlCmd) {
    if (curlCmd.isEmpty || curlCmd == '暂无请求记录' || curlCmd == '解析失败') return null;
    return 'https://curlconverter.com/#${Uri.encodeComponent(curlCmd)}';
  }
}
