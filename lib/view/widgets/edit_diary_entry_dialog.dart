import 'package:flutter/material.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/service/config_service.dart';

/// 通用编辑日记条目的对话框，支持普通条目和内容分析（summary）编辑与清空
class EditDiaryEntryDialog extends StatefulWidget {
  final Map<String, String> initialEntry;
  final List<String> allCategories;

  const EditDiaryEntryDialog({required this.initialEntry, required this.allCategories, super.key});

  @override
  State<EditDiaryEntryDialog> createState() => _EditDiaryEntryDialogState();
}

class _EditDiaryEntryDialogState extends State<EditDiaryEntryDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _summaryController;
  late String _category;
  late TimeOfDay _time;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _initCategories();
    _titleController = TextEditingController(text: widget.initialEntry['title'] ?? '');
    _contentController = TextEditingController(text: widget.initialEntry['q'] ?? '');
    _summaryController = TextEditingController(text: widget.initialEntry['a'] ?? '');
    final initCat = widget.initialEntry['category'];
    _category = initCat ?? '';
    final timeStr = widget.initialEntry['time'] ?? '';
    final timeParts = timeStr.split(':');
    if (timeParts.length == 2) {
      _time = TimeOfDay(hour: int.tryParse(timeParts[0]) ?? 8, minute: int.tryParse(timeParts[1]) ?? 0);
    } else {
      _time = const TimeOfDay(hour: 8, minute: 0);
    }
  }

  Future<void> _initCategories() async {
    final config = await AppConfigService.load();
    final list = config.getCategoryList();
    setState(() {
      _categories = List<String>.from(list);
      // 如果当前category不在列表中，插入到第一位
      if (_category.isNotEmpty && !_categories.contains(_category)) {
        _categories.insert(0, _category);
      }
      // 不再自动选第一个，保持为空
      // if (_category.isEmpty && _categories.isNotEmpty) {
      //   _category = _categories.first;
      // }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _clearContent() {
    setState(() {
      _contentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.edit,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.title,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _categories.isNotEmpty && _category.isNotEmpty ? _category : null,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v ?? ''),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.category,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      hintText: _categories.isEmpty ? '' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.time,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(_time.format(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _contentController,
              maxLines: 5,
              minLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.editDiary,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _summaryController,
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.aiSummaryResult,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: Text(AppLocalizations.of(context)!.cancel),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(AppLocalizations.of(context)!.save),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () {
                      Navigator.of(context).pop({
                        'title': _titleController.text.trim(),
                        'time': _time.format(context),
                        'category': _category,
                        'q': _contentController.text.trim(),
                        'a': _summaryController.text.trim(),
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
