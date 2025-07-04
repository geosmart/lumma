class DiaryDao {
  /// 公共的日记内容格式化方法
  /// [title] 日记标题（如问题或AI生成标题）
  /// [answer] 用户回答或AI分析
  /// [category] 分类（可为空）
  /// [time] 时间（可为空，默认当前时间）
  /// [content] 日记内容（如问题本身）
  /// [analysis] 内容分析（如AI回答，可为空）
  static String formatDiaryContent({
    required String title,
    required String content,
    required String analysis,
    String? category,
    String? time,
  }) {
    final buffer = StringBuffer();
    // 1. 标题
    buffer.writeln('## $title');
    buffer.writeln();
    // 2. 时间
    final now = DateTime.now();
    final timeStr = time ?? '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    buffer.writeln('### 时间');
    buffer.writeln(timeStr);
    buffer.writeln();
    // 3. 分类
    buffer.writeln('### 分类');
    buffer.writeln(category ?? '');
    buffer.writeln();
    // 4. 日记内容
    buffer.writeln('### 日记内容');
    buffer.writeln(content);
    buffer.writeln();
    // 5. 内容分析
    buffer.writeln('### 内容分析');
    buffer.writeln(analysis);
    buffer.writeln();
    // 分割线
    buffer.writeln('---');
    buffer.writeln();
    return buffer.toString();
  }

  /// 解析markdown为对话轮的函数，返回List<Map<String, String>>
  /// 每一轮包含：title, time, category, q, a
  static List<Map<String, String>> parseDiaryMarkdownToChatHistory(String content) {
    final lines = content.split('\n');
    final List<Map<String, String>> chatHistory = [];
    Map<String, String> currentItem = {};
    String? currentSection;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('## ')) {
        // 新的一轮，先保存上一轮
        if (currentItem.isNotEmpty) chatHistory.add(currentItem);
        currentItem = {'title': trimmed.substring(3)};
        currentSection = null;
      } else if (trimmed.startsWith('### ')) {
        // 标记当前section
        if (trimmed.contains('时间')) {
          currentSection = 'time';
        } else if (trimmed.contains('分类')) {
          currentSection = 'category';
        } else if (trimmed.contains('日记内容')) {
          currentSection = 'q';
        } else if (trimmed.contains('内容分析')) {
          currentSection = 'a';
        } else {
          currentSection = null;
        }
      } else if (trimmed == '---') {
        // 轮结束
        if (currentItem.isNotEmpty) chatHistory.add(currentItem);
        currentItem = {};
        currentSection = null;
      } else if (currentSection != null && trimmed.isNotEmpty) {
        // 累加section内容
        currentItem[currentSection] =
            (currentItem[currentSection] ?? '') + (currentItem[currentSection]?.isNotEmpty == true ? '\n' : '') + trimmed;
      }
    }
    // 收尾
    if (currentItem.isNotEmpty) chatHistory.add(currentItem);
    // 按时间降序排序（最近的在前面）
    chatHistory.sort((a, b) {
      final t1 = a['time'] ?? '';
      final t2 = b['time'] ?? '';
      return t2.compareTo(t1);
    });
    return chatHistory;
  }
}
