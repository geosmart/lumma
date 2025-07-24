import 'package:flutter/material.dart';
import '../config/config_service.dart';
import '../config/theme_service.dart';
import '../config/settings_ui_config.dart';
import '../generated/l10n/app_localizations.dart';

class CategoryConfigPage extends StatefulWidget {
  const CategoryConfigPage({super.key});

  @override
  State<CategoryConfigPage> createState() => _CategoryConfigPageState();
}

class _CategoryConfigPageState extends State<CategoryConfigPage> {
  late Future<List<String>> _categoriesFuture;
  final List<TextEditingController> _controllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _initAndLoadCategories();
  }

  Future<List<String>> _initAndLoadCategories() async {
    final config = await AppConfigService.load();
    final categories = config.getCategoryList();
    _controllers.clear();
    for (var c in categories) {
      _controllers.add(TextEditingController(text: c));
    }
    return categories;
  }

  void _addCategory() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  Future<void> _saveCategories() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final categories = _controllers.map((c) => c.text).where((e) => e.trim().isNotEmpty).toList();
      if (categories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分类不能为空')));
        setState(() { _isLoading = false; });
        return;
      }
      await AppConfigService.update((c) => c.categoryList = List<String>.from(categories));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分类已保存')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: context.backgroundGradient,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.category, color: context.primaryTextColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  '总结分类',
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
            child: FutureBuilder<List<String>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: \\${snapshot.error}',
                      style: TextStyle(color: context.primaryTextColor, fontSize: SettingsUiConfig.titleFontSize),
                    ),
                  );
                }
                return _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      )
                    : _controllers.isEmpty
                    ? Center(
                        child: Text(
                          '暂无分类',
                          style: TextStyle(color: context.secondaryTextColor, fontSize: SettingsUiConfig.titleFontSize),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _controllers.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.borderColor, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _controllers[index],
                                      style: TextStyle(
                                        color: context.primaryTextColor,
                                        fontSize: SettingsUiConfig.titleFontSize,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: '分类${index + 1}',
                                        labelStyle: TextStyle(
                                          color: context.secondaryTextColor,
                                          fontSize: SettingsUiConfig.subtitleFontSize,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: context.borderColor),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: context.borderColor),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('新增分类'),
                    onPressed: _addCategory,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(
                        fontSize: SettingsUiConfig.titleFontSize,
                        fontWeight: SettingsUiConfig.titleFontWeight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('保存'),
                    onPressed: _isLoading ? null : _saveCategories,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: TextStyle(
                        fontSize: SettingsUiConfig.titleFontSize,
                        fontWeight: SettingsUiConfig.titleFontWeight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
