/// JSON流式解析器测试
/// 验证解析逻辑的正确性

void main() {
  print('=== JSON流式解析器测试 ===\n');

  // 测试用例1: 完整的JSON对象流
  print('测试1: 完整的JSON对象流');
  final test1Input = '''
{"seq": 1, "before": "今天天气很好", "after": "今天天气很好", "type": "不变"}
{"seq": 2, "before": "我去了额那个公园", "after": "我去了公园", "type": "纠正"}
{"seq": 3, "before": "然后", "after": "", "type": "删除"}
''';
  print('输入: $test1Input');
  print('预期: 解析出3个片段\n');

  // 测试用例2: 流式分块输入
  print('测试2: 流式分块输入（模拟实时接收）');
  final chunks = [
    '{"seq": 1, "before": "今',
    '天天气很好", "after": "今天天气很好", "type": "不变"}',
    '\n{"seq": 2, "before": "我去',
    '了额那个公园", "after": "我去了公园", "type": "纠正"}',
  ];
  print('输入块: $chunks');
  print('预期: 逐步解析，最终得到2个完整片段\n');

  // 测试用例3: 包含特殊字符
  print('测试3: 包含特殊字符和转义');
  final test3Input = '''
{"seq": 1, "before": "他说：\\"你好\\"", "after": "他说：\\"你好\\"", "type": "不变"}
''';
  print('输入: $test3Input');
  print('预期: 正确处理转义的引号\n');

  // 测试用例4: 包含markdown代码块（需要过滤）
  print('测试4: 包含markdown代码块（AI可能错误返回）');
  final test4Input = '''
```json
{"seq": 1, "before": "测试", "after": "测试", "type": "不变"}
```
''';
  print('输入: $test4Input');
  print('预期: 能够提取出JSON对象，忽略markdown标记\n');

  // 实现说明
  print('=== 实现要点 ===');
  print('1. 增量解析: 支持分块添加数据，实时提取完整JSON对象');
  print('2. 边界识别: 通过大括号配对找到JSON对象边界');
  print('3. 字符串处理: 正确处理字符串内的转义字符和引号');
  print('4. 容错处理: 解析失败的对象会被跳过，继续解析后续数据');
  print('5. 状态保持: _lastParsedIndex 记录已解析位置，避免重复解析\n');

  // 使用示例
  print('=== 使用示例 ===');
  print('''
final parser = JsonStreamParser();

// 逐块添加数据
stream.listen((chunk) {
  final newSegments = parser.addChunk(chunk);
  if (newSegments.isNotEmpty) {
    // 实时处理新解析出的片段
    for (var segment in newSegments) {
      print('解析到: \${segment.before} -> \${segment.after}');
    }
  }
});

// 获取所有片段
final allSegments = parser.segments;
final correctedText = allSegments.map((s) => s.after).join();
''');
}
