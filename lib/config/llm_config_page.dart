import 'package:flutter/material.dart';
import '../model/llm_config.dart';
import 'config_service.dart';
import 'theme_service.dart';
import 'settings_ui_config.dart';
import 'llm_edit_page.dart';
import '../generated/l10n/app_localizations.dart';

class LLMConfigPage extends StatefulWidget {
  const LLMConfigPage({super.key});

  @override
  State<LLMConfigPage> createState() => _LLMConfigPageState();
}

class _LLMConfigPageState extends State<LLMConfigPage> {
  List<LLMConfig> _configs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final appConfig = await AppConfigService.load();
    setState(() {
      _configs = List<LLMConfig>.from(appConfig.model);
      _loading = false;
    });
  }

  void _showEditDialog({LLMConfig? config, int? index}) async {
    final result = await Navigator.of(context).push<LLMConfig>(
      MaterialPageRoute(
        builder: (context) => LLMEditPage(config: config),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _configs[index] = result;
        } else {
          _configs.add(result);
        }
      });
      await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));
    }
  }

  void _deleteConfig(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.llmDeleteConfirmTitle),
        content: Text(AppLocalizations.of(context)!.llmDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(context)!.llmCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppLocalizations.of(context)!.llmDelete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _configs.removeAt(index);
      await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));
      setState(() {});
    }
  }

  void _setActive(int index) async {
    for (var i = 0; i < _configs.length; i++) {
      _configs[i] = LLMConfig(
        provider: _configs[i].provider,
        baseUrl: _configs[i].baseUrl,
        apiKey: _configs[i].apiKey,
        model: _configs[i].model,
        active: i == index,
        created: _configs[i].created,
        updated: DateTime.now(),
      );
    }
    await AppConfigService.update((c) => c.model = List<LLMConfig>.from(_configs));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.backgroundGradient,
        ),
      ),
      child: _loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // 页面标题
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.memory,
                            color: context.primaryTextColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context)!.llmManage,
                            style: TextStyle(
                              fontSize: SettingsUiConfig.titleFontSize,
                              fontWeight: SettingsUiConfig.titleFontWeight,
                              color: context.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _configs.isEmpty
                          ? Center(
                              child: Text(
                                AppLocalizations.of(context)!.llmNone,
                                style: TextStyle(
                                  color: context.secondaryTextColor,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _configs.length,
                              itemBuilder: (ctx, i) {
                                final c = _configs[i];
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: context.cardBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.borderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      leading: IconButton(
                                        icon: Icon(
                                          c.active ? Icons.check_circle : Icons.circle_outlined,
                                          color: c.active ? Colors.green : context.secondaryTextColor,
                                          size: 22,
                                        ),
                                        onPressed: () => _setActive(i),
                                        tooltip: AppLocalizations.of(context)!.llmSetActive,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.provider,
                                            style: TextStyle(
                                              fontSize: SettingsUiConfig.subtitleFontSize,
                                              color: context.secondaryTextColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.model,
                                            style: TextStyle(
                                              fontSize: SettingsUiConfig.titleFontSize,
                                              color: context.primaryTextColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Spacer(),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.copy,
                                                  size: 20,
                                                  color: context.secondaryTextColor,
                                                ),
                                                onPressed: () {
                                                  final copy = LLMConfig(
                                                    provider: c.provider,
                                                    baseUrl: c.baseUrl,
                                                    apiKey: c.apiKey,
                                                    model: c.model,
                                                    active: c.active,
                                                    created: c.created,
                                                    updated: DateTime.now(),
                                                  );
                                                  _showEditDialog(config: copy);
                                                },
                                                tooltip: AppLocalizations.of(context)!.llmCopy,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.edit,
                                                  size: 20,
                                                  color: context.secondaryTextColor,
                                                ),
                                                onPressed: () => _showEditDialog(config: c, index: i),
                                                tooltip: AppLocalizations.of(context)!.llmEdit,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 20,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () => _deleteConfig(i),
                                                tooltip: AppLocalizations.of(context)!.llmDelete,
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: null,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      heroTag: 'add-model',
                      onPressed: () => _showEditDialog(),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      tooltip: AppLocalizations.of(context)!.llmAdd,
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
