import 'package:lumma/service/config_service.dart';
import 'package:lumma/model/enums.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Future<String> getDiaryQaTitle(BuildContext context) async {
  final mode = await AppConfigService.loadDiaryMode();
  if (mode == DiaryMode.qa) {
    return AppLocalizations.of(context)!.fixedQA;
  } else if (mode == DiaryMode.chat) {
    return AppLocalizations.of(context)!.aiChat;
  }
  return AppLocalizations.of(context)!.diary;
}
