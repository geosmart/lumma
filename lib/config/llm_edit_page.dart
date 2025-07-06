import 'package:flutter/material.dart';
import '../model/llm_config.dart';
import '../generated/l10n/app_localizations.dart';

class LLMEditPage extends StatefulWidget {
  final LLMConfig? config;

  const LLMEditPage({super.key, this.config});

  @override
  State<LLMEditPage> createState() => _LLMEditPageState();
}

class _LLMEditPageState extends State<LLMEditPage> {
  late TextEditingController _providerCtrl;
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;
  bool _isDefault = false;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _providerCtrl = TextEditingController(text: config?.provider ?? '');
    _baseUrlCtrl = TextEditingController(text: config?.baseUrl ?? '');
    _apiKeyCtrl = TextEditingController(text: config?.apiKey ?? '');
    _modelCtrl = TextEditingController(text: config?.model ?? '');
    _isDefault = config?.provider == 'default';
  }

  @override
  void dispose() {
    _providerCtrl.dispose();
    _baseUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  void _saveConfig() {
    final newConfig = LLMConfig(
      provider: _providerCtrl.text,
      baseUrl: _baseUrlCtrl.text,
      apiKey: _apiKeyCtrl.text,
      model: _modelCtrl.text,
      active: widget.config?.active ?? false,
      created: widget.config?.created,
      updated: DateTime.now(),
    );
    Navigator.of(context).pop(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? AppLocalizations.of(context)!.llmEditAddTitle : AppLocalizations.of(context)!.llmEditEditTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _providerCtrl,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.llmEditProvider),
                      readOnly: _isDefault,
                    ),
                    TextField(
                      controller: _baseUrlCtrl,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.llmEditBaseUrl),
                      readOnly: _isDefault,
                    ),
                    TextField(
                      controller: _apiKeyCtrl,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.llmEditApiKey,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureApiKey ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscureApiKey = !_obscureApiKey;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureApiKey,
                      readOnly: _isDefault,
                    ),
                    TextField(
                      controller: _modelCtrl,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.llmEditModel),
                      readOnly: _isDefault,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton.icon(
                onPressed: _isDefault ? null : _saveConfig,
                icon: const Icon(Icons.save),
                label: Text(AppLocalizations.of(context)!.llmEditSave),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
