import 'package:flutter/material.dart';
import '../config/model_config.dart';

class ModelEditPage extends StatefulWidget {
  final ModelConfig? config;

  const ModelEditPage({super.key, this.config});

  @override
  State<ModelEditPage> createState() => _ModelEditPageState();
}

class _ModelEditPageState extends State<ModelEditPage> {
  late TextEditingController _providerCtrl;
  late TextEditingController _baseUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _providerCtrl = TextEditingController(text: config?.provider ?? '');
    _baseUrlCtrl = TextEditingController(text: config?.baseUrl ?? '');
    _apiKeyCtrl = TextEditingController(text: config?.apiKey ?? '');
    _modelCtrl = TextEditingController(text: config?.model ?? '');
    // Assuming the default model has a specific provider name, e.g., 'default'
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
    final newConfig = ModelConfig(
      provider: _providerCtrl.text,
      baseUrl: _baseUrlCtrl.text,
      apiKey: _apiKeyCtrl.text,
      model: _modelCtrl.text,
      active: widget.config?.active ?? false,
    );
    Navigator.of(context).pop(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? '添加模型' : '编辑模型'),
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
                      decoration: const InputDecoration(labelText: 'Provider'),
                      readOnly: _isDefault,
                    ),
                    TextField(
                      controller: _baseUrlCtrl,
                      decoration: const InputDecoration(labelText: 'Base URL'),
                      readOnly: _isDefault,
                    ),
                    TextField(
                      controller: _apiKeyCtrl,
                      decoration: const InputDecoration(labelText: 'API Key'),
                      readOnly: _isDefault,
                    ),
                    TextField(
                      controller: _modelCtrl,
                      decoration: const InputDecoration(labelText: 'Model'),
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
                label: const Text('保存'),
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
