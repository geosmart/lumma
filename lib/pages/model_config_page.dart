import 'package:flutter/material.dart';
import '../models/model_config.dart';
import '../services/config_service.dart';
import '../services/theme_service.dart';
import 'model_edit_page.dart';
import '../config/settings_ui_config.dart';

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
      // 按 provider+model 名称升序排序
      _configs = configs..sort((a, b) => ('${a.provider}-${a.model}').compareTo('${b.provider}-${b.model}'));
      _loading = false;
    });
  }

  void _showEditDialog({ModelConfig? config, int? index}) async {
    final result = await Navigator.of(context).push<ModelConfig>(
      MaterialPageRoute(
        builder: (context) => ModelEditPage(config: config),
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
      await ConfigService.saveModelConfigs(_configs);
    }
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
        active: i == index,
      );
    }
    print('[model_config_page] 设置激活 configs: ' + _configs.map((c) => c.toJson().toString()).join(','));
    await ConfigService.saveModelConfigs(_configs);
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
                            '模型管理',
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
                                '暂无模型',
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
                                        tooltip: '设为激活',
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
                                          Text(
                                            c.model,
                                            style: TextStyle(
                                              fontSize: SettingsUiConfig.titleFontSize,
                                              color: context.primaryTextColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.copy,
                                              size: 20,
                                              color: context.secondaryTextColor,
                                            ),
                                            onPressed: () {
                                              final copy = ModelConfig.fromJson(c.toJson());
                                              _showEditDialog(config: copy);
                                            },
                                            tooltip: '复制',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              size: 20,
                                              color: context.secondaryTextColor,
                                            ),
                                            onPressed: () => _showEditDialog(config: c, index: i),
                                            tooltip: '编辑',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteConfig(i),
                                            tooltip: '删除',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
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
                      child: const Icon(Icons.add, size: 28),
                      tooltip: '添加模型',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
