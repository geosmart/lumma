/// JSON流式解析器容错测试
/// 测试各种边界情况和错误格式的处理

import 'package:lumma/util/json_stream_parser.dart';

void main() {
  print('=== JSON流式解析器容错测试 ===\n');

  // 测试1: 错误格式 {]}
  print('测试1: 处理错误格式 {]}');
  final parser1 = JsonStreamParser();
  parser1.addChunk('{]}');
  parser1.addChunk('{"seq": 1, "before": "正常", "after": "正常", "type": "不变"}');
  print('输入: {]}{"seq": 1, "before": "正常", "after": "正常", "type": "不变"}');
  print('结果: 解析到 ${parser1.segments.length} 个片段');
  print('验证: ${parser1.segments.length == 1 ? "✓ 通过" : "✗ 失败"}\n');

  // 测试2: 错误格式 {]
  print('测试2: 处理错误格式 {]');
  final parser2 = JsonStreamParser();
  parser2.addChunk('{]{"seq": 1, "before": "测试", "after": "测试", "type": "不变"}');
  print('输入: {]{"seq": 1, "before": "测试", "after": "测试", "type": "不变"}');
  print('结果: 解析到 ${parser2.segments.length} 个片段');
  print('验证: ${parser2.segments.length == 1 ? "✓ 通过" : "✗ 失败"}\n');

  // 测试3: markdown代码块包裹
  print('测试3: 处理markdown代码块包裹 ```json\\n{...}```');
  final parser3 = JsonStreamParser();
  parser3.addChunk('```json\n{"seq": 1, "before": "测试", "after": "测试", "type": "不变"}```');
  print('输入: ```json\\n{"seq": 1, "before": "测试", "after": "测试", "type": "不变"}```');
  print('结果: 解析到 ${parser3.segments.length} 个片段');
  if (parser3.segments.isNotEmpty) {
    print('片段内容: before="${parser3.segments[0].before}", after="${parser3.segments[0].after}"');
  }
  print('验证: ${parser3.segments.length == 1 ? "✓ 通过" : "✗ 失败"}\n');

  // 测试4: 分片到达的不完整JSON
  print('测试4: 分片到达的不完整JSON');
  final parser4 = JsonStreamParser();
  var segments = parser4.addChunk('{"seq": 1, "before": "这是');
  print('第1片: {"seq": 1, "before": "这是 -> 解析到 ${segments.length} 个');
  segments = parser4.addChunk('一个长句子", "after": "');
  print('第2片: 一个长句子", "after": " -> 解析到 ${segments.length} 个');
  segments = parser4.addChunk('这是一个长句子", "type": "不变"}');
  print('第3片: 这是一个长句子", "type": "不变"} -> 解析到 ${segments.length} 个');
  print('最终结果: ${parser4.segments.length} 个完整片段');
  print('验证: ${parser4.segments.length == 1 ? "✓ 通过" : "✗ 失败"}\n');

  // 测试5: 混合文本和JSON
  print('测试5: 混合非JSON文本和JSON对象');
  final parser5 = JsonStreamParser();
  parser5.addChunk('这是一些说明文字{"seq": 1, "before": "内容", "after": "内容", "type": "不变"}还有更多文字');
  print('输入: 这是一些说明文字{"seq": 1, ...}还有更多文字');
  print('结果: 解析到 ${parser5.segments.length} 个片段');
  print('验证: ${parser5.segments.length == 1 ? "✓ 通过" : "✗ 失败"}\n');

  // 测试6: 多个连续JSON对象
  print('测试6: 多个连续JSON对象（无分隔符）');
  final parser6 = JsonStreamParser();
  parser6.addChunk(
    '{"seq": 1, "before": "第一", "after": "第一", "type": "不变"}'
    '{"seq": 2, "before": "第二", "after": "第二", "type": "不变"}'
    '{"seq": 3, "before": "第三", "after": "第三", "type": "不变"}'
  );
  print('输入: {...}{...}{...} (3个连续对象)');
  print('结果: 解析到 ${parser6.segments.length} 个片段');
  print('验证: ${parser6.segments.length == 3 ? "✓ 通过" : "✗ 失败"}\n');

  // 测试7: 包含转义字符
  print('测试7: 包含转义引号的JSON');
  final parser7 = JsonStreamParser();
  parser7.addChunk('{"seq": 1, "before": "他说:\\"你好\\"", "after": "他说:\\"你好\\"", "type": "不变"}');
  print('输入: {"seq": 1, "before": "他说:\\\\"你好\\\\"", ...}');
  print('结果: 解析到 ${parser7.segments.length} 个片段');
  if (parser7.segments.isNotEmpty) {
    print('before内容: "${parser7.segments[0].before}"');
  }
  print('验证: ${parser7.segments.length == 1 && parser7.segments[0].before.contains('"你好"') ? "✓ 通过" : "✗ 失败"}\n');

  // 测试8: 真实场景模拟
  print('测试8: 真实AI返回场景（带markdown+流式+错误）');
  final parser8 = JsonStreamParser();
  parser8.addChunk('```json\n');
  parser8.addChunk('{"seq": 1, "before": "额，今天天气');
  parser8.addChunk('真不错啊。", "after": "今天天气真不错。", "type": "纠正"}');
  parser8.addChunk('\n{"seq": 2, "before": "那个嗯", "after": "", "type": "删除"}');
  parser8.addChunk('\n{]}'); // 错误格式
  parser8.addChunk('\n{"seq": 3, "before": "我去了公园。", "after": "我去了公园。", "type": "不变"}');
  parser8.addChunk('\n```');

  print('模拟AI逐步返回（包含markdown和错误格式）');
  print('结果: 解析到 ${parser8.segments.length} 个有效片段');
  print('片段详情:');
  for (var seg in parser8.segments) {
    print('  seq=${seg.seq}, type=${seg.type}, before="${seg.before}", after="${seg.after}"');
  }
  print('验证: ${parser8.segments.length == 3 ? "✓ 通过" : "✗ 失败"}\n');

  // 测试9: 缺失字段使用默认值
  print('测试9: JSON缺失字段时使用默认值');
  final parser9 = JsonStreamParser();
  parser9.addChunk('{"seq": 1}'); // 只有seq字段
  print('输入: {"seq": 1}');
  print('结果: 解析到 ${parser9.segments.length} 个片段');
  if (parser9.segments.isNotEmpty) {
    print('默认值: before="${parser9.segments[0].before}", after="${parser9.segments[0].after}", type="${parser9.segments[0].type}"');
  }
  print('验证: ${parser9.segments.length == 1 && parser9.segments[0].type == "不变" ? "✓ 通过" : "✗ 失败"}\n');

  // 测试10: 完全无效的JSON
  print('测试10: 完全无效的JSON');
  final parser10 = JsonStreamParser();
  parser10.addChunk('{invalid json}');
  parser10.addChunk('{"seq": 1, "before": "正常", "after": "正常", "type": "不变"}');
  print('输入: {invalid json}{"seq": 1, ...}');
  print('结果: 解析到 ${parser10.segments.length} 个有效片段');
  print('验证: ${parser10.segments.length == 1 ? "✓ 通过 (跳过无效JSON)" : "✗ 失败"}\n');

  // 总结
  print('=== 容错特性总结 ===');
  print('✓ 自动过滤markdown代码块标记 (```json)');
  print('✓ 跳过错误格式如 {]}, {]}');
  print('✓ 处理不完整JSON（等待更多数据）');
  print('✓ 忽略无效JSON，继续解析后续内容');
  print('✓ 支持字段缺失时的默认值');
  print('✓ 正确处理转义字符');
  print('✓ 支持混合文本和JSON');
  print('✓ 支持连续JSON对象（无分隔符）\n');
}
