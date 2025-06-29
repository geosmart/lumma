import '../config/config_service.dart';

class QaQuestionsService {
  static Future<void> init() async {
    final config = await AppConfigService.load();
    if (config.qaQuestions.isEmpty) {
      await AppConfigService.update((c) => c.qaQuestions = [
            '今天哪些细节引起了你的注意？',
            '今天谁做了什么具体的事？',
            '今天你做成了什么事？',
            '什么时候你感到开心、轻松或觉得有趣？',
            '今天你收到了哪些支持或善意？',
            '今天你遇到了哪些外部挑战？',
            '你在什么时候感受到不适的情绪？',
            '你的身体有没有发出一些信号？',
            '我今天又出现了什么反应模式？',
            '针对今日问题制定明日可行的小步优化？',
          ]);
    }
  }

  // 新增: 持久化 QA 问题配置到 lumma_config.json
  static Future<void> save() async {
    // 假设 QA 问题已在 AppConfig 中，直接调用 AppConfigService.save()
    await AppConfigService.save();
  }
}
