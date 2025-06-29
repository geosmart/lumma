import 'timestamped.dart';

class QAQuestionConfig extends Timestamped {
  String question;
  String category;
  bool enabled;

  QAQuestionConfig({
    required this.question,
    required this.category,
    this.enabled = true,
    DateTime? created,
    DateTime? updated,
  }) : super(created: created, updated: updated);

  /// 创建默认的问题配置列表
  static List<QAQuestionConfig> defaultQuestions() => [
        // 外部观察
        QAQuestionConfig(
          question: "今天，你的感官捕捉到了哪些特别的细节？比如，特定的光影、不经意的声音、某种气味，或是某个空间里让你印象深刻的布局？",
          category: "observe_environment",
        ),
        QAQuestionConfig(
          question: "今天，你注意到身边的人（家人、同事、朋友或陌生人）有什么具体的言行举止吗？也许是一句话，一个表情，或一个不经意的动作？",
          category: "observe_people",
        ),
        // 美好瞬间
        QAQuestionConfig(
          question: "今天你有没有完成什么事，让你感到一丝成就感？无论大小，比如推进了一个计划，学到了新东西，或者只是完成了一件一直想做的小事。",
          category: "good_achievement",
        ),
        QAQuestionConfig(
          question: "在哪个时刻，你感受到了纯粹的喜悦、轻松或有趣？当时和谁在一起，是什么事情或氛围触发了这份感觉？",
          category: "good_joy",
        ),
        QAQuestionConfig(
          question: "今天，你是否感受到了来自他人或生活的善意与支持？可能是一句温暖的回应、一个及时的帮助，甚至是享受到的美食、看到的风景。有什么让你心怀感激吗？",
          category: "good_gratitude",
        ),
        // 挑战与感受
        QAQuestionConfig(
          question: "今天遇到了什么挑战或不太顺利的事吗？比如，事情在哪一步卡住了，或者被意外打断了？",
          category: "difficult_challenge",
        ),
        QAQuestionConfig(
          question: "在哪个瞬间，你觉察到了自己的不适感（比如焦虑、烦躁、失落、愤怒等）？那一刻，你的内在和外在正在发生什么？",
          category: "difficult_emotion",
        ),
        QAQuestionConfig(
          question: "你的身体今天向你发出了什么信号吗（比如疲惫、酸痛、紧绷）？你是否留意到了这些信号，又是如何回应它的？",
          category: "difficult_body",
        ),
        // 觉察与迭代
        QAQuestionConfig(
          question: "回顾今天，你有没有发现自己重复出现的某些反应模式？比如，是不是又习惯性地自责、拖延、急于向他人解释，或是忽略了自己的真实感受？",
          category: "different_awareness",
        ),
        QAQuestionConfig(
          question: "基于今天的经历（某个挑战、情绪或身体感受），你愿意为明天设定一个怎样的微小、可行的优化步骤？比如'会议上少说一句，多听一分钟'或'感觉累时，主动休息五分钟'。",
          category: "different_improvement",
        ),
      ];

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
