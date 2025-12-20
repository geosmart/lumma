/// 流式纠错界面对话框
/// 显示AI实时纠错过程，基于JSON流式解析，逐句显示差异对比
library;

import 'package:flutter/material.dart';
import '../../util/json_stream_parser.dart';

/// 流式纠错对话框
class TextCorrectionStreamDialog extends StatefulWidget {
  final String originalText;
  final Stream<String> correctionStream;

  const TextCorrectionStreamDialog({
    Key? key,
    required this.originalText,
    required this.correctionStream,
  }) : super(key: key);

  @override
  State<TextCorrectionStreamDialog> createState() =>
      _TextCorrectionStreamDialogState();
}

class _TextCorrectionStreamDialogState
    extends State<TextCorrectionStreamDialog> {
  final JsonStreamParser _parser = JsonStreamParser();
  List<CorrectionSegment> _segments = [];
  bool _isCompleted = false;
  String? _errorMessage;
  final Set<int> _renderedSeqs = {}; // 记录已渲染的seq，避免重复

  @override
  void initState() {
    super.initState();
    _listenToStream();
  }

  void _listenToStream() {
    widget.correctionStream.listen(
      (chunk) {
        final newSegments = _parser.addChunk(chunk);
        // 只有当解析出新片段时才更新UI
        if (newSegments.isNotEmpty) {
          setState(() {
            // 只添加未渲染过的片段
            for (final segment in newSegments) {
              if (!_renderedSeqs.contains(segment.seq)) {
                _segments.add(segment);
                _renderedSeqs.add(segment.seq);
              }
            }
          });
        }
      },
      onDone: () {
        setState(() {
          _isCompleted = true;
        });
      },
      onError: (error) {
        setState(() {
          _isCompleted = true;
          _errorMessage = error.toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 关闭按钮
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, size: 24),
                onPressed: () => Navigator.of(context).pop(null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 16),

            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                child: _errorMessage != null
                    ? _buildErrorView(isDark)
                    : _buildContentWithDiff(isDark),
              ),
            ),

            const SizedBox(height: 16),

            // 底部状态指示
            if (!_isCompleted)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI 纠错中...',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '纠错失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '未知错误',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContentWithDiff(bool isDark) {
    if (_segments.isEmpty) {
      // 还没有收到任何片段，显示原文
      return Text(
        widget.originalText,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
        ),
      );
    }

    // 根据主题选择颜色
    final normalColor = isDark ? Colors.white.withOpacity(0.87) : Colors.black87;
    final deleteColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final insertColor = isDark ? const Color(0xFFCE93D8) : const Color(0xFFBA68C8); // 浅紫色

    final spans = <InlineSpan>[];

    for (final segment in _segments) {
      final before = segment.before.trim();
      final after = segment.after.trim();
      final type = segment.type;

      if (type == '删除') {
        // 删除：只显示删除线的原文（灰色）
        if (before.isNotEmpty) {
          spans.add(TextSpan(
            text: before,
            style: TextStyle(
              color: deleteColor,
              decoration: TextDecoration.lineThrough,
              decorationColor: deleteColor,
            ),
          ));
        }
      } else if (type == '纠正') {
        // 纠正：计算before和after的字符级差异，逐字对比
        if (before != after) {
          final diffs = _computeCharDiff(before, after);
          for (final diff in diffs) {
            if (diff['type'] == 'delete') {
              // 删除的字符：灰色删除线
              spans.add(TextSpan(
                text: diff['text'],
                style: TextStyle(
                  color: deleteColor,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: deleteColor,
                ),
              ));
            } else if (diff['type'] == 'insert') {
              // 插入/修改的字符：浅紫色
              spans.add(TextSpan(
                text: diff['text'],
                style: TextStyle(
                  color: insertColor,
                  fontWeight: FontWeight.w500,
                ),
              ));
            } else {
              // 不变的字符：正常显示
              spans.add(TextSpan(
                text: diff['text'],
                style: TextStyle(color: normalColor),
              ));
            }
          }
        } else {
          // before和after相同，正常显示
          spans.add(TextSpan(
            text: after,
            style: TextStyle(color: normalColor),
          ));
        }
      } else if (type == '不变') {
        // 不变：正常显示
        if (after.isNotEmpty) {
          spans.add(TextSpan(
            text: after,
            style: TextStyle(color: normalColor),
          ));
        }
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: normalColor,
        ),
        children: spans,
      ),
    );
  }

  /// 计算字符级差异（基于最长公共子序列LCS算法）
  List<Map<String, String>> _computeCharDiff(String before, String after) {
    if (before == after) {
      return [{'type': 'equal', 'text': after}];
    }

    // 使用LCS算法计算差异
    final lcs = _computeLCS(before, after);
    final result = <Map<String, String>>[];

    int i = 0, j = 0;
    final lcsChars = lcs.split('');

    for (final lcsChar in lcsChars) {
      // 处理before中删除的字符
      while (i < before.length && before[i] != lcsChar) {
        result.add({'type': 'delete', 'text': before[i]});
        i++;
      }
      // 处理after中插入的字符
      while (j < after.length && after[j] != lcsChar) {
        result.add({'type': 'insert', 'text': after[j]});
        j++;
      }
      // 相同的字符
      if (i < before.length && j < after.length) {
        result.add({'type': 'equal', 'text': lcsChar});
        i++;
        j++;
      }
    }

    // 处理剩余的字符
    while (i < before.length) {
      result.add({'type': 'delete', 'text': before[i]});
      i++;
    }
    while (j < after.length) {
      result.add({'type': 'insert', 'text': after[j]});
      j++;
    }

    // 合并相邻相同类型的字符
    return _mergeAdjacentDiffs(result);
  }

  /// 计算最长公共子序列
  String _computeLCS(String a, String b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1];
        }
      }
    }

    // 回溯构建LCS
    final lcs = StringBuffer();
    int i = m, j = n;
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        lcs.write(a[i - 1]);
        i--;
        j--;
      } else if (dp[i - 1][j] > dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }

    return lcs.toString().split('').reversed.join('');
  }

  /// 合并相邻相同类型的差异
  List<Map<String, String>> _mergeAdjacentDiffs(List<Map<String, String>> diffs) {
    if (diffs.isEmpty) return diffs;

    final merged = <Map<String, String>>[];
    String? currentType;
    final currentText = StringBuffer();

    for (final diff in diffs) {
      if (currentType == diff['type']) {
        // 相同类型，合并文本
        currentText.write(diff['text']);
      } else {
        // 不同类型，保存之前的并开始新的
        if (currentType != null && currentText.isNotEmpty) {
          merged.add({'type': currentType, 'text': currentText.toString()});
        }
        currentType = diff['type'];
        currentText.clear();
        currentText.write(diff['text']);
      }
    }

    // 添加最后一个
    if (currentType != null && currentText.isNotEmpty) {
      merged.add({'type': currentType, 'text': currentText.toString()});
    }

    return merged;
  }
}
