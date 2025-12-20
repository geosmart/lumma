/// 文本差异对比工具
/// 用于识别纠错前后的文本变化，包括删除和修改
library;

/// 文本差异类型
enum DiffType {
  equal, // 相同部分
  delete, // 删除部分
  insert, // 插入/修改部分
}

/// 文本差异片段
class DiffSegment {
  final String text;
  final DiffType type;

  DiffSegment({
    required this.text,
    required this.type,
  });

  @override
  String toString() => 'DiffSegment(text: "$text", type: $type)';
}

/// 文本差异对比结果
class TextDiffResult {
  final List<DiffSegment> segments;

  TextDiffResult(this.segments);

  /// 获取原始文本（包含删除部分）
  String get originalText {
    final buffer = StringBuffer();
    for (var segment in segments) {
      if (segment.type != DiffType.insert) {
        buffer.write(segment.text);
      }
    }
    return buffer.toString();
  }

  /// 获取修正后文本（不包含删除部分）
  String get correctedText {
    final buffer = StringBuffer();
    for (var segment in segments) {
      if (segment.type != DiffType.delete) {
        buffer.write(segment.text);
      }
    }
    return buffer.toString();
  }
}

/// 文本差异对比工具类
class TextDiffUtil {
  /// 简单的基于字符级别的差异对比算法
  /// 返回差异片段列表
  static TextDiffResult diff(String original, String corrected) {
    if (original == corrected) {
      return TextDiffResult([
        DiffSegment(text: original, type: DiffType.equal),
      ]);
    }

    final segments = <DiffSegment>[];
    final origChars = original.split('');
    final corrChars = corrected.split('');

    // 使用动态规划算法计算最长公共子序列
    final lcs = _longestCommonSubsequence(origChars, corrChars);

    int origIndex = 0;
    int corrIndex = 0;
    int lcsIndex = 0;

    while (origIndex < origChars.length || corrIndex < corrChars.length) {
      // 如果原始文本和LCS不匹配，说明这部分被删除了
      if (lcsIndex < lcs.length &&
          origIndex < origChars.length &&
          origChars[origIndex] == lcs[lcsIndex]) {
        // 这是公共部分
        final commonStart = origIndex;
        while (lcsIndex < lcs.length &&
            origIndex < origChars.length &&
            origChars[origIndex] == lcs[lcsIndex]) {
          origIndex++;
          corrIndex++;
          lcsIndex++;
        }
        segments.add(DiffSegment(
          text: origChars.sublist(commonStart, origIndex).join(),
          type: DiffType.equal,
        ));
      } else if (origIndex < origChars.length &&
          (lcsIndex >= lcs.length || origChars[origIndex] != lcs[lcsIndex])) {
        // 原始文本中有但LCS中没有，说明被删除
        final deleteStart = origIndex;
        while (origIndex < origChars.length &&
            (lcsIndex >= lcs.length || origChars[origIndex] != lcs[lcsIndex])) {
          origIndex++;
        }
        segments.add(DiffSegment(
          text: origChars.sublist(deleteStart, origIndex).join(),
          type: DiffType.delete,
        ));
      } else if (corrIndex < corrChars.length &&
          (lcsIndex >= lcs.length || corrChars[corrIndex] != lcs[lcsIndex])) {
        // 修正文本中有但LCS中没有，说明是新增/修改
        final insertStart = corrIndex;
        while (corrIndex < corrChars.length &&
            (lcsIndex >= lcs.length || corrChars[corrIndex] != lcs[lcsIndex])) {
          corrIndex++;
        }
        segments.add(DiffSegment(
          text: corrChars.sublist(insertStart, corrIndex).join(),
          type: DiffType.insert,
        ));
      }
    }

    return TextDiffResult(_mergeSegments(segments));
  }

  /// 计算最长公共子序列
  static List<String> _longestCommonSubsequence(
      List<String> a, List<String> b) {
    final m = a.length;
    final n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    // 填充DP表
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
    final lcs = <String>[];
    int i = m, j = n;
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        lcs.insert(0, a[i - 1]);
        i--;
        j--;
      } else if (dp[i - 1][j] > dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }

    return lcs;
  }

  /// 合并相邻的相同类型片段
  static List<DiffSegment> _mergeSegments(List<DiffSegment> segments) {
    if (segments.isEmpty) return segments;

    final merged = <DiffSegment>[];
    DiffSegment? current;

    for (var segment in segments) {
      if (current == null || current.type != segment.type) {
        if (current != null) merged.add(current);
        current = segment;
      } else {
        current = DiffSegment(
          text: current.text + segment.text,
          type: current.type,
        );
      }
    }

    if (current != null) merged.add(current);
    return merged;
  }

  /// 智能文本差异对比（基于词语级别）
  /// 对于中文文本更友好
  static TextDiffResult smartDiff(String original, String corrected) {
    if (original == corrected) {
      return TextDiffResult([
        DiffSegment(text: original, type: DiffType.equal),
      ]);
    }

    // 将文本分割成词语和标点
    final origWords = _tokenize(original);
    final corrWords = _tokenize(corrected);

    final segments = <DiffSegment>[];
    final lcs = _longestCommonSubsequence(origWords, corrWords);

    int origIndex = 0;
    int corrIndex = 0;
    int lcsIndex = 0;

    while (origIndex < origWords.length || corrIndex < corrWords.length) {
      if (lcsIndex < lcs.length &&
          origIndex < origWords.length &&
          origWords[origIndex] == lcs[lcsIndex]) {
        // 公共部分
        final commonStart = origIndex;
        while (lcsIndex < lcs.length &&
            origIndex < origWords.length &&
            origWords[origIndex] == lcs[lcsIndex]) {
          origIndex++;
          corrIndex++;
          lcsIndex++;
        }
        segments.add(DiffSegment(
          text: origWords.sublist(commonStart, origIndex).join(),
          type: DiffType.equal,
        ));
      } else if (origIndex < origWords.length &&
          (lcsIndex >= lcs.length || origWords[origIndex] != lcs[lcsIndex])) {
        // 删除部分
        final deleteStart = origIndex;
        while (origIndex < origWords.length &&
            (lcsIndex >= lcs.length || origWords[origIndex] != lcs[lcsIndex])) {
          origIndex++;
        }
        segments.add(DiffSegment(
          text: origWords.sublist(deleteStart, origIndex).join(),
          type: DiffType.delete,
        ));
      } else if (corrIndex < corrWords.length) {
        // 插入/修改部分
        final insertStart = corrIndex;
        while (corrIndex < corrWords.length &&
            (lcsIndex >= lcs.length ||
                corrWords[corrIndex] != lcs[lcsIndex])) {
          corrIndex++;
        }
        segments.add(DiffSegment(
          text: corrWords.sublist(insertStart, corrIndex).join(),
          type: DiffType.insert,
        ));
      }
    }

    return TextDiffResult(_mergeSegments(segments));
  }

  /// 将文本分词（支持中英文混合）
  static List<String> _tokenize(String text) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    bool lastWasChinese = false;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final isChinese = _isChineseChar(char);
      final isPunctuation = _isPunctuation(char);

      if (isPunctuation) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        tokens.add(char);
        lastWasChinese = false;
      } else if (isChinese) {
        if (buffer.isNotEmpty && !lastWasChinese) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        buffer.write(char);
        lastWasChinese = true;
      } else {
        if (buffer.isNotEmpty && lastWasChinese) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        buffer.write(char);
        lastWasChinese = false;
      }
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  /// 判断是否为中文字符
  static bool _isChineseChar(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 0x4E00 && code <= 0x9FFF) || // CJK统一汉字
        (code >= 0x3400 && code <= 0x4DBF) || // CJK扩展A
        (code >= 0x20000 && code <= 0x2A6DF); // CJK扩展B
  }

  /// 判断是否为标点符号
  static bool _isPunctuation(String char) {
    if (char.isEmpty) return false;
    final punctuations = '，。！？；：、""''（）《》【】…—·,.!?;:\'"()[]{}';
    return punctuations.contains(char);
  }
}
