import 'package:flutter/material.dart';
import '../services/diary_mode_config_service.dart';

Future<String> getDiaryQaTitle() async {
  int mode = await DiaryModeConfigService.loadDiaryMode();
  if (mode == 1) {
    return '本地问答式日记';
  }
  return 'AI 问答式日记';
}
