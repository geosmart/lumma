/// chat_history_service.dart
/// Chat history management to keep the UI layer lean
library;

class ChatHistoryService {
  static const int maxHistory = 20;

  /// Add a new conversation round, automatically trim history length
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

  /// Update the answer for the current round
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

  /// Update the question for the current round
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

  /// Get the last N rounds of history
  static List<Map<String, String>> getRecent(
    List<Map<String, String>> history, {
    int window = maxHistory,
  }) {
    if (history.length <= window) return List<Map<String, String>>.from(history);
    return history.sublist(history.length - window);
  }
}
