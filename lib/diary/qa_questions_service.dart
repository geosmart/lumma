import 'package:flutter/widgets.dart';
import '../generated/l10n/app_localizations.dart';
import '../config/config_service.dart';

class QaQuestionsService {
  static Future<void> init(BuildContext context) async {
    final config = await AppConfigService.load();
    if (config.qaQuestions.isEmpty) {
      await AppConfigService.update((c) => c.qaQuestions = [
            AppLocalizations.of(context)!.qaQuestion1,
            AppLocalizations.of(context)!.qaQuestion2,
            AppLocalizations.of(context)!.qaQuestion3,
            AppLocalizations.of(context)!.qaQuestion4,
            AppLocalizations.of(context)!.qaQuestion5,
            AppLocalizations.of(context)!.qaQuestion6,
            AppLocalizations.of(context)!.qaQuestion7,
            AppLocalizations.of(context)!.qaQuestion8,
            AppLocalizations.of(context)!.qaQuestion9,
            AppLocalizations.of(context)!.qaQuestion10,
          ]);
    }
  }

  // Save QA question config to lumma_config.json
  static Future<void> save() async {
    // Assume QA questions are already in AppConfig, just call AppConfigService.save()
    await AppConfigService.save();
  }
}

// TODO: Add i18n keys for QA questions to l10n/app_zh.arb and l10n/app_en.arb if not present
