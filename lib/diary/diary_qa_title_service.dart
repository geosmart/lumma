import '../config/diary_mode_config_service.dart';
import '../model/enums.dart';

Future<String> getDiaryQaTitle() async {
  final mode = await DiaryModeConfigService.loadDiaryMode();
  if (mode == DiaryMode.qa) {
    return '固定问答模式';
  } else if (mode == DiaryMode.chat) {
    return '自由聊天模式';
  }
  return 'AI 日记';
}
