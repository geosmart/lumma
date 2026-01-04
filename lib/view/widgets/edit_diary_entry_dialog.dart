import 'package:flutter/material.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';

/// 通用编辑日记条目的对话框
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
  late String _category;
  late TimeOfDay _time;
  late DateTime? _originalDateTime; // Store original date for preserving it
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _initCategories();
    _titleController = TextEditingController(text: widget.initialEntry['title'] ?? '');
    _contentController = TextEditingController(text: widget.initialEntry['q'] ?? '');
    final initCat = widget.initialEntry['category'];
    _category = initCat ?? '';

    // Parse time from full format (yyyy-MM-dd HH:mm:ss) or legacy format (HH:mm)
    final timeStr = widget.initialEntry['time'] ?? '';
    DateTime? parsedDateTime;

    if (timeStr.contains(' ')) {
      // Full format: yyyy-MM-dd HH:mm:ss
      try {
        final parts = timeStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');
          if (dateParts.length == 3 && timeParts.length >= 2) {
            parsedDateTime = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              int.parse(timeParts[0]),
              int.parse(timeParts[1]),
              timeParts.length >= 3 ? int.parse(timeParts[2]) : 0,
            );
            _time = TimeOfDay(hour: parsedDateTime.hour, minute: parsedDateTime.minute);
          }
        }
      } catch (e) {
        print('Failed to parse full time format: $e');
      }
    } else {
      // Legacy format: HH:mm or HH:mm:ss
      final timeParts = timeStr.split(':');
      if (timeParts.length >= 2) {
        _time = TimeOfDay(hour: int.tryParse(timeParts[0]) ?? 8, minute: int.tryParse(timeParts[1]) ?? 0);
        // Use today's date as fallback
        parsedDateTime = DateTime.now();
      }
    }

    _originalDateTime = parsedDateTime;

    // Fallback to current time if parsing failed
    if (_originalDateTime == null) {
      _time = const TimeOfDay(hour: 8, minute: 0);
      _originalDateTime = DateTime.now();
    }
  }

  Future<void> _initCategories() async {
    setState(() {
      _categories = [];
      // 如果当前category不在列表中，插入到第一位
      if (_category.isNotEmpty && !_categories.contains(_category)) {
        _categories.insert(0, _category);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
                    initialValue: _categories.isNotEmpty && _category.isNotEmpty ? _category : null,
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
                      // Build full time format: yyyy-MM-dd HH:mm:ss
                      final baseDate = _originalDateTime ?? DateTime.now();
                      final updatedDateTime = DateTime(
                        baseDate.year,
                        baseDate.month,
                        baseDate.day,
                        _time.hour,
                        _time.minute,
                        baseDate.second,
                      );
                      final fullTimeStr = '${updatedDateTime.year}-${updatedDateTime.month.toString().padLeft(2, '0')}-${updatedDateTime.day.toString().padLeft(2, '0')} ${updatedDateTime.hour.toString().padLeft(2, '0')}:${updatedDateTime.minute.toString().padLeft(2, '0')}:${updatedDateTime.second.toString().padLeft(2, '0')}';

                      Navigator.of(context).pop({
                        'title': _titleController.text.trim(),
                        'time': fullTimeStr,
                        'category': _category,
                        'q': _contentController.text.trim(),
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
