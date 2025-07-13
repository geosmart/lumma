import 'timestamped.dart';

class QAQuestionConfig extends Timestamped {
  String question;
  String category;
  bool enabled;

  QAQuestionConfig({required this.question, required this.category, this.enabled = true, super.created, super.updated});

  factory QAQuestionConfig.fromMap(Map map) => QAQuestionConfig(
    question: map['question'] ?? '',
    category: map['category'] ?? '',
    enabled: map['enabled'] ?? true,
    created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
    updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'question': question,
    'category': category,
    'enabled': enabled,
    'created': created.toIso8601String(),
    'updated': updated.toIso8601String(),
  };
}
