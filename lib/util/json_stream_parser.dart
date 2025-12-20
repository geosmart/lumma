/// JSON流式解析器
/// 用于解析流式返回的JSON对象序列，逐个提取纠错片段
/// 支持容错处理：markdown代码块包裹、错误格式如{]}、不完整JSON等
library;

import 'dart:convert';

/// 纠错片段数据模型
class CorrectionSegment {
  final int seq;
  final String before;
  final String after;
  final String type; // "纠正"、"删除"、"不变"

  CorrectionSegment({
    required this.seq,
    required this.before,
    required this.after,
    required this.type,
  });

  factory CorrectionSegment.fromJson(Map<String, dynamic> json) {
    return CorrectionSegment(
      seq: json['seq'] as int? ?? 0,
      before: json['before'] as String? ?? '',
      after: json['after'] as String? ?? '',
      type: json['type'] as String? ?? '不变',
    );
  }

  @override
  String toString() => 'CorrectionSegment(seq: $seq, before: "$before", after: "$after", type: $type)';
}

/// JSON流式解析器
/// 从流式返回的文本中逐步提取JSON对象
/// 容错特性：
/// 1. 自动清理markdown代码块标记（```json\n{...}```）
/// 2. 跳过错误格式如{]}、{]、}}等
/// 3. 处理不完整JSON（等待更多数据）
/// 4. 忽略非JSON文本
class JsonStreamParser {
  final StringBuffer _buffer = StringBuffer();
  final List<CorrectionSegment> _segments = [];
  int _lastParsedIndex = 0;

  /// 添加新的数据块
  /// 返回新解析出的片段列表
  List<CorrectionSegment> addChunk(String chunk) {
    _buffer.write(chunk);
    return _parseNewSegments();
  }

  /// 获取所有已解析的片段
  List<CorrectionSegment> get segments => List.unmodifiable(_segments);

  /// 获取当前缓冲区内容（调试用）
  String get buffer => _buffer.toString();

  /// 解析新的片段
  List<CorrectionSegment> _parseNewSegments() {
    final newSegments = <CorrectionSegment>[];
    final text = _buffer.toString();

    // 跳过已解析的部分
    int searchStart = _lastParsedIndex;

    while (true) {
      // 查找下一个JSON对象的开始位置
      int objectStart = text.indexOf('{', searchStart);
      if (objectStart == -1) break;

      // 检查是否是错误格式如 {]} 或 {]
      if (_isInvalidBraceSequence(text, objectStart)) {
        // 跳过这个错误的开始位置
        searchStart = objectStart + 1;
        _lastParsedIndex = searchStart;
        continue;
      }

      // 查找匹配的结束大括号
      int objectEnd = _findMatchingBrace(text, objectStart);
      if (objectEnd == -1) {
        // 没有找到匹配的大括号，可能数据还不完整
        // 但也可能是错误格式，检查是否有多余的 }
        int nextBrace = text.indexOf('}', objectStart + 1);
        if (nextBrace != -1 && nextBrace < text.length - 1) {
          // 有结束括号但匹配失败，可能是错误格式，跳过
          searchStart = objectStart + 1;
          continue;
        }
        // 真的是不完整，等待更多数据
        break;
      }

      // 提取JSON字符串并解析
      try {
        String jsonStr = text.substring(objectStart, objectEnd + 1);

        // 清理可能的markdown代码块标记
        jsonStr = jsonStr.replaceAll(RegExp(r'```json\s*'), '');
        jsonStr = jsonStr.replaceAll(RegExp(r'```\s*'), '');

        final jsonData = jsonDecode(jsonStr) as Map<String, dynamic>;

        // 验证必须字段
        if (!_isValidCorrectionSegment(jsonData)) {
          // 不是有效的纠错片段，跳过
          searchStart = objectEnd + 1;
          _lastParsedIndex = searchStart;
          continue;
        }

        final segment = CorrectionSegment.fromJson(jsonData);

        // 检查是否已经存在相同seq的片段（去重）
        if (!_segments.any((s) => s.seq == segment.seq)) {
          _segments.add(segment);
          newSegments.add(segment);
        }

        // 更新搜索位置
        searchStart = objectEnd + 1;
        _lastParsedIndex = searchStart;
      } catch (e) {
        // JSON解析失败，继续查找下一个
        searchStart = objectEnd + 1;
        _lastParsedIndex = searchStart;
      }
    }

    return newSegments;
  }

  /// 检查是否是无效的大括号序列
  /// 例如：{]} 或 {] 或 }} 或 }{
  bool _isInvalidBraceSequence(String text, int start) {
    if (start + 1 >= text.length) return false;

    final next = text[start + 1];
    // {] 是明显的错误格式
    if (next == ']') return true;

    // 检查 {]} 格式
    if (start + 2 < text.length) {
      final nextTwo = text.substring(start + 1, start + 3);
      if (nextTwo == ']}') return true;
    }

    return false;
  }

  /// 验证是否是有效的纠错片段JSON
  bool _isValidCorrectionSegment(Map<String, dynamic> json) {
    // 必须包含这些字段
    return json.containsKey('seq') &&
           json.containsKey('before') &&
           json.containsKey('after') &&
           json.containsKey('type');
  }

  /// 查找匹配的右大括号
  int _findMatchingBrace(String text, int start) {
    int depth = 0;
    bool inString = false;
    bool escaping = false;

    for (int i = start; i < text.length; i++) {
      final char = text[i];

      if (escaping) {
        escaping = false;
        continue;
      }

      if (char == '\\') {
        escaping = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') {
          depth++;
        } else if (char == '}') {
          depth--;
          if (depth == 0) {
            return i;
          }
          // 如果depth变成负数，说明格式错误
          if (depth < 0) {
            return -1;
          }
        } else if (char == ']' && depth > 0) {
          // 在对象内部遇到 ]，这是错误格式如 {]}
          return -1;
        }
      }
    }

    return -1; // 没有找到匹配的大括号
  }

  /// 重置解析器
  void reset() {
    _buffer.clear();
    _segments.clear();
    _lastParsedIndex = 0;
  }
}
