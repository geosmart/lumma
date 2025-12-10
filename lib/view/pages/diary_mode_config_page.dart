import 'package:flutter/material.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/service/config_service.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/config/settings_ui_config.dart';
import 'package:lumma/model/enums.dart' as model_enums;

class DiaryModeConfigPage extends StatefulWidget {
  const DiaryModeConfigPage({super.key});

  @override
  State<DiaryModeConfigPage> createState() => _DiaryModeConfigPageState();
}

class _DiaryModeConfigPageState extends State<DiaryModeConfigPage> {
  model_enums.DiaryMode _mode = model_enums.DiaryMode.qa;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMode();
  }

  Future<void> _loadMode() async {
    final mode = await AppConfigService.loadDiaryMode();
    setState(() {
      _mode = mode;
      _loading = false;
    });
  }

  Future<void> _setMode(model_enums.DiaryMode mode) async {
    setState(() {
      _mode = mode;
    });
    await AppConfigService.saveDiaryMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.backgroundGradient,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.auto_stories, color: context.primaryTextColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.diaryMode,
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.all(4)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            child: ListTile(
              leading: Icon(
                _mode == model_enums.DiaryMode.chat ? Icons.check_circle : Icons.circle_outlined,
                color: _mode == model_enums.DiaryMode.chat ? Colors.green : context.secondaryTextColor,
                size: 22,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.aiChat,
                    style: TextStyle(fontSize: SettingsUiConfig.titleFontSize, color: context.primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.aiChatDescription,
                style: TextStyle(color: context.secondaryTextColor, fontSize: SettingsUiConfig.subtitleFontSize),
              ),
              onTap: () => _setMode(model_enums.DiaryMode.chat),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            child: ListTile(
              leading: Icon(
                _mode == model_enums.DiaryMode.qa ? Icons.check_circle : Icons.circle_outlined,
                color: _mode == model_enums.DiaryMode.qa ? Colors.green : context.secondaryTextColor,
                size: 22,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.fixedQA,
                    style: TextStyle(fontSize: SettingsUiConfig.titleFontSize, color: context.primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.fixedQADescription,
                style: TextStyle(color: context.secondaryTextColor, fontSize: SettingsUiConfig.subtitleFontSize),
              ),
              onTap: () => _setMode(model_enums.DiaryMode.qa),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor, width: 1),
            ),
            child: ListTile(
              leading: Icon(
                _mode == model_enums.DiaryMode.timeline ? Icons.check_circle : Icons.circle_outlined,
                color: _mode == model_enums.DiaryMode.timeline ? Colors.green : context.secondaryTextColor,
                size: 22,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.timeline,
                    style: TextStyle(fontSize: SettingsUiConfig.titleFontSize, color: context.primaryTextColor),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.timelineDescription,
                style: TextStyle(color: context.secondaryTextColor, fontSize: SettingsUiConfig.subtitleFontSize),
              ),
              onTap: () => _setMode(model_enums.DiaryMode.timeline),
            ),
          ),
        ],
      ),
    );
  }
}
