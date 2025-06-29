import '../config/diary_mode_config_service.dart';

Future<String> getDiaryQaTitle() async {
  String mode = await DiaryModeConfigService.loadDiaryMode();
  if (mode == 'qa') {
    return '固定问答模式';
  } else if (mode == 'chat') {
    return '自由聊天模式';
  }
  return 'AI 日记';
}
