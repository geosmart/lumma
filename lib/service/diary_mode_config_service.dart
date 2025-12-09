import 'package:lumma/service/config_service.dart';
import 'package:lumma/model/enums.dart';

/// Service for managing diary mode configuration
class DiaryModeConfigService {
  /// Load the current diary mode from app config
  static Future<DiaryMode> loadDiaryMode() async {
    final config = await AppConfigService.load();
    return config.diaryMode;
  }

  /// Save the diary mode to app config
  static Future<void> saveDiaryMode(DiaryMode mode) async {
    await AppConfigService.update((config) {
      config.diaryMode = mode;
    });
  }

  /// 新增: 持久化日记模式配置到 lumma_config.json
  static Future<void> save() async {
    // 假设 diaryMode 已在 AppConfig 中，直接调用 AppConfigService.save()
    await AppConfigService.save();
  }

  /// Initialize the diary mode config if needed
  static Future<void> init() async {
    // The AppConfig constructor already sets a default DiaryMode.qa
    // No additional initialization needed
  }
}
