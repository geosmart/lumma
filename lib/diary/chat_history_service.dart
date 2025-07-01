/// chat_history_service.dart
/// 聊天历史管理，便于 UI 层瘦身
library;

class ChatHistoryService {
  static const int maxHistory = 20;

  /// 新增一轮对话，自动裁剪历史长度
  static List<Map<String, String>> addHistory(
    List<Map<String, String>> history, {
    required String question,
    String answer = '',
  }) {
    final newHistory = List<Map<String, String>>.from(history);
    newHistory.add({'q': question, 'a': answer});
    if (newHistory.length > maxHistory) newHistory.removeAt(0);
    return newHistory;
  }

  /// 更新当前轮的回答
  static List<Map<String, String>> updateAnswer(
    List<Map<String, String>> history,
    int index,
    String answer,
  ) {
    final newHistory = List<Map<String, String>>.from(history);
    if (index >= 0 && index < newHistory.length) {
      newHistory[index]['a'] = answer;
    }
    return newHistory;
  }

  /// 更新当前轮的问题
  static List<Map<String, String>> updateQuestion(
    List<Map<String, String>> history,
    int index,
    String question,
  ) {
    final newHistory = List<Map<String, String>>.from(history);
    if (index >= 0 && index < newHistory.length) {
      newHistory[index]['q'] = question;
    }
    return newHistory;
  }

  /// 获取最近 N 轮历史
  static List<Map<String, String>> getRecent(
    List<Map<String, String>> history, {
    int window = maxHistory,
  }) {
    if (history.length <= window) return List<Map<String, String>>.from(history);
    return history.sublist(history.length - window);
  }
}
