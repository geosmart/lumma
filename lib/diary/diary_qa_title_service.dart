import '../config/diary_mode_config_service.dart';
import '../model/enums.dart';
import '../generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<String> getDiaryQaTitle(BuildContext context) async {
  final mode = await DiaryModeConfigService.loadDiaryMode();
  if (mode == DiaryMode.qa) {
    return AppLocalizations.of(context)!.fixedQA;
  } else if (mode == DiaryMode.chat) {
    return AppLocalizations.of(context)!.aiChat;
  }
  return AppLocalizations.of(context)!.diary;
}
