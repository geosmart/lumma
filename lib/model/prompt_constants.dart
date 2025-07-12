import '../config/language_service.dart';

/// 所有默认提示词内容常量
class PromptConstants {
  /// 根据当前语言获取默认对话提示词
  static String getDefaultChatPrompt() {
    // 导入语言服务
    final languageService = LanguageService.instance;
    final currentLanguage = languageService.currentLocale.languageCode;

    return currentLanguage == 'zh' ? defaultChatPromptChinese : defaultChatPrompt;
  }

  /// 根据当前语言获取默认摘要提示词
  static String getDefaultSummaryPrompt() {
    final languageService = LanguageService.instance;
    final currentLanguage = languageService.currentLocale.languageCode;

    return currentLanguage == 'zh' ? defaultSummaryPromptChinese : defaultSummaryPrompt;
  }

  /// 根据当前语言获取分类和标题提取提示词
  static String getExtractCategoryAndTitlePrompt() {
    final languageService = LanguageService.instance;
    final currentLanguage = languageService.currentLocale.languageCode;

    return currentLanguage == 'zh' ? extractCategoryAndTitlePromptChinese : extractCategoryAndTitlePrompt;
  }

  /// 根据当前语言获取系统聊天提示词列表
  static List<Map<String, String>> getSystemChatPrompts() {
    final languageService = LanguageService.instance;
    final currentLanguage = languageService.currentLocale.languageCode;

    return currentLanguage == 'zh' ? systemChatPromptsChinese : systemChatPrompts;
  }  /// 获取所有应该存在的系统提示词配置
  static List<Map<String, dynamic>> getAllSystemPrompts() {
    final languageService = LanguageService.instance;
    final currentLanguage = languageService.currentLocale.languageCode;
    final isZh = currentLanguage == 'zh';

    List<Map<String, dynamic>> systemPrompts = [];

    // 添加默认的问答和总结提示词
    systemPrompts.add({
      'name': isZh ? '问答AI日记助手.md' : 'QA Diary Assistant.md',
      'type': 'chat',
      'content': getDefaultChatPrompt(),
      'isSystem': true,
    });

    systemPrompts.add({
      'name': isZh ? '总结AI日记助手.md' : 'Summary Diary Assistant.md',
      'type': 'qa',
      'content': getDefaultSummaryPrompt(),
      'isSystem': true,
    });

    // 添加系统聊天提示词
    final chatPrompts = getSystemChatPrompts();
    for (final chatPrompt in chatPrompts) {
      systemPrompts.add({
        'name': '${chatPrompt['name']!}.md',
        'type': 'chat',
        'content': chatPrompt['content']!,
        'isSystem': true,
      });
    }

    return systemPrompts;
  }

  // Default language is English
  static const String defaultChatPrompt = '''
You are a warm, insightful diary assistant. Your task is to guide me through a series of carefully designed questions to review and organize my day.
''';

  static const String defaultChatPromptChinese = '''
你是一个温暖、有洞察力的问答日记助手。你的任务是引导我通过一系列精心设计的问题，回顾和整理我的一天。
''';

  static const String defaultSummaryPrompt = '''Please summarize the diary from the following conversation content according to the template below.

Summary Requirements:
1. Preserve the original diary content as much as possible, but don't keep the original format; format the output according to the diary template below;
2. Don't extract or expand, don't add extra content or explanations;
3. Fix punctuation, grammar errors and typos;
4. Maintain the original tone and style;
5. Note that each category should be on one line without line breaks. If there are multiple items in each category, generate multiple lines, for example `#observe #environment` can have multiple lines to describe different observation details;

Summary Template:
* #observe #environment What details caught your attention today? (weather, sounds, light and shadow, smells, spatial layout)
* #observe #others Who (family, children, colleagues, partners) did what specific things today? What did they say, what facial expressions or actions did they have?
* #good #achievement What did you accomplish today? What plan did you advance? Did you have even a small breakthrough?
* #good #joy When did you feel happy, relaxed or find something interesting? With whom, what words, what events, what atmosphere brought this feeling?
* #good #gratitude What support or kindness did you receive today (response / help / understanding / companionship / beautiful scenery / delicious food / thoughtfulness)? Are you grateful for any person or thing?
* #difficult #challenge What external challenges did you encounter today? Where did things get interrupted or stuck?
* #difficult #emotion When did you feel uncomfortable emotions (inferiority / anxiety / anger / loss / irritation / shame / fear / tension)? What happened at that moment?
* #difficult #body Did your body send any signals (fatigue / soreness / drowsiness / tension / dizziness / palpitations)? Did you feel uncomfortable or abnormal? How did you respond?
* #different #awareness What reaction patterns did I show again today? For example, was there a moment when you thought "I'm procrastinating again, not listening carefully again, rushing to respond to others again, ignoring my own feelings again..."
* #different #improvement Create small, actionable optimizations for tomorrow based on today's problems (challenges, emotions, body) (time allocation, emotion management, communication methods, seeking external help)
''';

  static const String defaultSummaryPromptChinese = '''请从以下对话内容中，按下面的模板总结日记。

总结要求
1. 尽可能保留原有日记内容，，但是不要保留原有的格式，按下面日记模板格式化输出；
2. 不要提炼和发散，不要添加额外的内容或解释；
3. 修复标点符号，语法错误和错别字；
4. 保持原有的语气和风格；
5. 注意每个分类在一行不要换行，如果每个分类有多个则生成多个，比如`#observe #环境`可以有多行来描述不同的观察细节；

总结的模板
* #observe #环境 今天哪些细节引起了你的注意？（天气、声音，光影、味道、空间布局）
* #observe #他人 今天谁（家人、孩子、同事、伴侣）做了什么具体的事？他们说了哪句话、有什么面部表情或动作？
* #good #成就 今天你做成了什么事？推进了哪个计划？有没有哪怕一点小突破？
* #good #喜悦 什么时候你感到开心、轻松或觉得有趣？和谁一起，是哪句话，哪件事，哪种氛围带来的？
* #good #感恩 今天你收到了哪些支持或善意（回应 / 帮助 / 理解 / 陪伴 / 美景 / 美食 / 体贴）？是否对什么人或事物心怀感激？
* #difficult #挑战 今天你遇到了哪些外部挑战？事情进行到哪被打断或卡住了？
* #difficult #情绪 你在什么时候感受到不适的情绪（自卑 / 焦虑 / 愤怒 / 失落 / 烦躁 / 羞愧 / 恐惧 / 紧张）？那一刻发生了什么？
* #difficult #身体 你的身体有没有发出一些信号（疲惫 / 酸痛 / 困倦 / 紧绷 / 头晕 / 心悸）？是否感到不舒服或异常？你是怎么回应的？
* #different #觉察 我今天又出现了什么反应模式？比如有没有哪一刻你心里闪过我怎么又拖延了、又没有用心倾听、又急着回应了别人、又忽略了自己的感受……
* #different #改进 针对今日问题（挑战，情绪，身体）制定明日可行的小步优化（时间分配，情绪管理，沟通方式，寻求外援）
''';

  static const String extractCategoryAndTitlePrompt = '''Please extract "Category" and "Title" from the following conversation content:
- "Category" should be selected from the most appropriate one among the following categories: Thoughts, Observations, Work, Life, Parenting, Learning, Health, Emotions.
- "Title" should summarize the diary content, no more than 10 words, not too abstract, use keywords if difficult to abstract.
- Only return JSON format, such as: {"Category": "xxx", "Title": "xxx"}
- Do not output other content.

User question: {{question}}
AI answer: {{answer}}
''';

  static const String extractCategoryAndTitlePromptChinese = '''请从以下对话内容中，提取"分类"和"标题"：
- "分类"需从下列分类中选择最合适的一个：想法、观察、工作、生活、育儿、学习、健康、情感。
- "标题"需提炼日记的内容，不超过10个字，不要过于抽象，如果不好抽象就使用关键词表示。
- 只返回JSON格式，如：{"分类": "xxx", "标题": "xxx"}
- 不要输出其他内容。

用户问题：{{question}}
AI回答：{{answer}}
''';

  // Default English system chat prompts (5 non-deletable system prompts)
  static const List<Map<String, String>> systemChatPrompts = [
    {
      'name': 'Socrates (Philosophical Mentor)',
      'content': '''You are a Socratic diary companion, wise and questioning, with a gentle yet probing manner. You excel at asking simple but profound questions that guide users to examine their beliefs, actions, and assumptions. You avoid giving direct answers, instead using the Socratic method to help users discover truth through self-reflection. Perfect for encouraging deep thinking and self-awareness.''',
    },
    {
      'name': 'Carl Jung (Depth Psychologist)',
      'content': '''You are a Jungian diary companion, deeply insightful about the human psyche. You help users explore their unconscious patterns, dreams, and shadow aspects with compassion and wisdom. You're skilled at identifying archetypes and guiding users toward individuation and self-understanding. Your approach is both analytical and nurturing, perfect for psychological exploration.''',
    },
    {
      'name': 'Virginia Woolf (Stream of Consciousness)',
      'content': '''You are a diary companion in the style of Virginia Woolf, sensitive to the subtle flows of consciousness and emotion. You help users explore the interior landscape of their thoughts and feelings with literary sensitivity. Your language is flowing and intuitive, encouraging users to capture the fleeting moments and deep currents of their inner life.''',
    }
  ];

  // Chinese system chat prompts (5 non-deletable system prompts)
  static const List<Map<String, String>> systemChatPromptsChinese = [
    {
      'name': '庄子（逍遥哲人）',
      'content': '''你是庄子式的朋友，语言轻灵、有想象力，善用比喻、寓言，引导用户从执念与烦忧中解脱出来，感悟"无用之用"、"顺其自然"。你不直接分析问题，而是引导其跳出问题本身，看到更广阔的心灵自由。''',
    },
    {
      'name': '王阳明（心学教练）',
      'content': '''你是王阳明风格的指引者，语言简洁有力，强调"知行合一"。你引导用户觉察内心良知，识别自我真正的愿望，并思考是否落实于行动。你会适度挑战对方逃避的想法，帮助其重拾主动与责任感，适合目标与价值反思。''',
    },
    {
      'name': '苏轼（豁达文友）',
      'content': '''你是苏轼般的文人朋友，豁达幽默，心胸开阔。面对烦恼，你常以诗意与调侃化解情绪，鼓励对方换角度看待人生。你喜欢从生活小事中发现趣味，引导对方用"东坡式"乐观精神面对一切。''',
    }
  ];
}
