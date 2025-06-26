import 'package:flutter/material.dart';
import '../models/model_config.dart';
import '../services/config_service.dart';

class ModelConfigPage extends StatefulWidget {
  const ModelConfigPage({super.key});

  @override
  State<ModelConfigPage> createState() => _ModelConfigPageState();
}

class _ModelConfigPageState extends State<ModelConfigPage> {
  List<ModelConfig> _configs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    print('[model_config_page] 调用 ensureDefaultConfig');
    await ConfigService.ensureDefaultConfig();
    final configs = await ConfigService.loadModelConfigs();
    print('[model_config_page] 读取到 configs: ' + configs.map((c) => c.toJson().toString()).join(','));
    setState(() {
      _configs = configs;
      _loading = false;
    });
  }

  void _showEditDialog({ModelConfig? config, int? index}) {
    final providerCtrl = TextEditingController(text: config?.provider ?? '');
    final baseUrlCtrl = TextEditingController(text: config?.baseUrl ?? '');
    final apiKeyCtrl = TextEditingController(text: config?.apiKey ?? '');
    final modelCtrl = TextEditingController(text: config?.model ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(config == null ? '添加模型' : '编辑模型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: providerCtrl,
                decoration: const InputDecoration(labelText: 'Provider'),
              ),
              TextField(
                controller: baseUrlCtrl,
                decoration: const InputDecoration(labelText: 'Base URL'),
              ),
              TextField(
                controller: apiKeyCtrl,
                decoration: const InputDecoration(labelText: 'API Key'),
              ),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newConfig = ModelConfig(
                provider: providerCtrl.text,
                baseUrl: baseUrlCtrl.text,
                apiKey: apiKeyCtrl.text,
                model: modelCtrl.text,
                isActive: config?.isActive ?? false,
              );
              if (index != null) {
                _configs[index] = newConfig;
              } else {
                _configs.add(newConfig);
              }
              print('[model_config_page] 保存 configs: ' + _configs.map((c) => c.toJson().toString()).join(','));
              await ConfigService.saveModelConfigs(_configs);
              setState(() {});
              // ignore: use_build_context_synchronously
              Navigator.of(ctx).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _deleteConfig(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除该模型吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _configs.removeAt(index);
      print('[model_config_page] 删除后 configs: ' + _configs.map((c) => c.toJson().toString()).join(','));
      await ConfigService.saveModelConfigs(_configs);
      setState(() {});
    }
  }

  void _setActive(int index) async {
    for (var i = 0; i < _configs.length; i++) {
      _configs[i] = ModelConfig(
        provider: _configs[i].provider,
        baseUrl: _configs[i].baseUrl,
        apiKey: _configs[i].apiKey,
        model: _configs[i].model,
        isActive: i == index,
      );
    }
    print('[model_config_page] 设置激活 configs: ' + _configs.map((c) => c.toJson().toString()).join(','));
    await ConfigService.saveModelConfigs(_configs);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _configs.isEmpty
                        ? const Center(child: Text('暂无模型'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _configs.length,
                            itemBuilder: (ctx, i) {
                              final c = _configs[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: Icon(
                                    c.isActive ? Icons.check_circle : Icons.circle_outlined,
                                    color: c.isActive ? Colors.green : null,
                                  ),
                                  title: Text('${c.provider} - ${c.model}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _showEditDialog(config: c, index: i),
                                        tooltip: '编辑',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteConfig(i),
                                        tooltip: '删除',
                                      ),
                                    ],
                                  ),
                                  onTap: () => _setActive(i),
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
                    child: const Icon(Icons.add, size: 28),
                    tooltip: '添加模型',
                  ),
                ),
              ),
            ],
          );
  }
}
