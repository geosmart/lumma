import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import 'language_service.dart';
import 'llm_config_page.dart';
import 'prompt_config_page.dart';
import 'diary_mode_config_page.dart';
import '../diary/qa_question_config_page.dart';
import 'sync_config_page.dart';
import 'theme_service.dart';
import 'settings_ui_config.dart';

class SettingsPage extends StatelessWidget {
  final int initialTabIndex;

  const SettingsPage({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      initialIndex: initialTabIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              Tab(icon: Icon(Icons.auto_stories, size: 20)),
              Tab(icon: Icon(Icons.chat, size: 20)),
              Tab(icon: Icon(Icons.memory, size: 20)),
              Tab(icon: Icon(Icons.question_answer, size: 20)),
              Tab(icon: Icon(Icons.sync, size: 20)),
              Tab(icon: Icon(Icons.palette, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DiaryModeConfigPage(),
            PromptConfigPage(),
            LLMConfigPage(),
            QaQuestionConfigPage(),
            SyncConfigPage(),
            _AppearanceSettingsPage(),
          ],
        ),
      ),
    );
  }
}

// Appearance settings page (including theme and language)
class _AppearanceSettingsPage extends StatefulWidget {
  const _AppearanceSettingsPage();

  @override
  State<_AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<_AppearanceSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: context.backgroundGradient,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          // Page title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: context.primaryTextColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.appearanceSettings,
                  style: TextStyle(
                    fontSize: SettingsUiConfig.titleFontSize,
                    fontWeight: SettingsUiConfig.titleFontWeight,
                    color: context.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          // Language settings
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language,
                        color: context.primaryTextColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.language,
                        style: TextStyle(
                          fontSize: SettingsUiConfig.titleFontSize,
                          fontWeight: SettingsUiConfig.titleFontWeight,
                          color: context.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chinese
                Container(
                  decoration: BoxDecoration(
                    color: LanguageService.instance.currentLocale.languageCode == 'zh'
                        ? const Color(0xFFF3E5AB).withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: LanguageService.instance.currentLocale.languageCode == 'zh'
                        ? Border.all(color: const Color(0xFFD4A574), width: 1.5)
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE2910),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          '中',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.languageChinese,
                      style: TextStyle(
                        fontSize: SettingsUiConfig.subtitleFontSize,
                        fontWeight: LanguageService.instance.currentLocale.languageCode == 'zh'
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: context.primaryTextColor,
                      ),
                    ),
                    trailing: LanguageService.instance.currentLocale.languageCode == 'zh'
                        ? const Icon(Icons.check_circle, color: Color(0xFFD4A574), size: 20)
                        : null,
                    onTap: () {
                      LanguageService.instance.setLanguage(const Locale('zh', 'CN'));
                    },
                  ),
                ),

                // English
                Container(
                  decoration: BoxDecoration(
                    color: LanguageService.instance.currentLocale.languageCode == 'en'
                        ? const Color(0xFFF3E5AB).withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: LanguageService.instance.currentLocale.languageCode == 'en'
                        ? Border.all(color: const Color(0xFFD4A574), width: 1.5)
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4C75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'EN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.languageEnglish,
                      style: TextStyle(
                        fontSize: SettingsUiConfig.subtitleFontSize,
                        fontWeight: LanguageService.instance.currentLocale.languageCode == 'en'
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: context.primaryTextColor,
                      ),
                    ),
                    trailing: LanguageService.instance.currentLocale.languageCode == 'en'
                        ? const Icon(Icons.check_circle, color: Color(0xFFD4A574), size: 20)
                        : null,
                    onTap: () {
                      LanguageService.instance.setLanguage(const Locale('en', 'US'));
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Theme switch card
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: context.primaryTextColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.theme,
                        style: TextStyle(
                          fontSize: SettingsUiConfig.titleFontSize,
                          fontWeight: SettingsUiConfig.titleFontWeight,
                          color: context.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Light theme
                Container(
                  decoration: BoxDecoration(
                    color: ThemeService.instance.themeMode == ThemeMode.light
                        ? const Color(0xFFF3E5AB).withOpacity(0.3)  // Use warm golden background when selected
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: ThemeService.instance.themeMode == ThemeMode.light
                        ? Border.all(color: const Color(0xFFD4A574), width: 1.5)  // Add golden border when selected
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFfdf7f0),
                            Color(0xFFf0e6d6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ThemeService.instance.themeMode == ThemeMode.light
                              ? const Color(0xFFD4A574)   // Use golden border when selected
                              : context.borderColor,
                          width: ThemeService.instance.themeMode == ThemeMode.light ? 3 : 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.wb_sunny,
                        color: Color(0xFF8d6e63),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.themeLightMode,
                      style: TextStyle(
                        fontWeight: ThemeService.instance.themeMode == ThemeMode.light
                            ? FontWeight.w600  // Bold font when selected
                            : FontWeight.w500,
                        color: context.primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.themeLightDesc,
                      style: TextStyle(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: ThemeService.instance.themeMode,
                      activeColor: const Color(0xFFD4A574),  // Light theme用金色
                      onChanged: (value) {
                        if (value != null) {
                          ThemeService.instance.setTheme(value);
                          setState(() {});
                        }
                      },
                    ),
                    onTap: () {
                      ThemeService.instance.setTheme(ThemeMode.light);
                      setState(() {});
                    },
                  ),
                ),

                Divider(color: context.borderColor, height: 1),

                // Dark theme
                Container(
                  decoration: BoxDecoration(
                    color: ThemeService.instance.themeMode == ThemeMode.dark
                        ? const Color(0xFF3B4CCA).withOpacity(0.2)  // 选中时用蓝紫色背景
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: ThemeService.instance.themeMode == ThemeMode.dark
                        ? Border.all(color: const Color(0xFF9FA8DA), width: 1.5)  // 选中时添加淡蓝色边框
                        : null,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1a1a2e),
                            Color(0xFF0f3460),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ThemeService.instance.themeMode == ThemeMode.dark
                              ? const Color(0xFF9FA8DA)   // 选中时用淡蓝色边框
                              : context.borderColor,
                          width: ThemeService.instance.themeMode == ThemeMode.dark ? 3 : 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.themeDarkMode,
                      style: TextStyle(
                        fontWeight: ThemeService.instance.themeMode == ThemeMode.dark
                            ? FontWeight.w600  // Bold font when selected
                            : FontWeight.w500,
                        color: context.primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      AppLocalizations.of(context)!.themeDarkDesc,
                      style: TextStyle(
                        color: context.secondaryTextColor,
                      ),
                    ),
                    trailing: Radio<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: ThemeService.instance.themeMode,
                      activeColor: const Color(0xFF9FA8DA),  // Dark theme用淡蓝色
                      onChanged: (value) {
                        if (value != null) {
                          ThemeService.instance.setTheme(value);
                          setState(() {});
                        }
                      },
                    ),
                    onTap: () {
                      ThemeService.instance.setTheme(ThemeMode.dark);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Preview card
          Container(
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.themePreview,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Simulate homepage style
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: context.backgroundGradient,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: context.primaryButtonGradient,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.appTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.primaryTextColor,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(context)!.appSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
