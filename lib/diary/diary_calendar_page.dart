import 'package:flutter/material.dart';
import 'diary_statistics_service.dart';
import 'diary_content_page.dart';
import '../dao/diary_dao.dart';
import '../generated/l10n/app_localizations.dart';

/// Diary calendar heatmap page showing character count by day
class DiaryCalendarPage extends StatefulWidget {
  const DiaryCalendarPage({super.key});

  @override
  State<DiaryCalendarPage> createState() => _DiaryCalendarPageState();
}

class _DiaryCalendarPageState extends State<DiaryCalendarPage> {
  Map<DateTime, int> _characterCounts = {};
  bool _loading = true;
  DateTime _displayDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loading = true);

    try {
      final counts = await DiaryStatisticsService.getCharacterCountByDate();
      setState(() {
        _characterCounts = counts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.loadingFailed}: $e')),
        );
      }
    }
  }

  Color _getColorForCount(int count, int maxCount) {
    if (count == 0) {
      return Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[200]!;
    }

    final intensity = DiaryStatisticsService.getIntensityLevel(count, maxCount);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (intensity) {
      case 4:
        return isDark ? Colors.green[700]! : Colors.green[700]!;
      case 3:
        return isDark ? Colors.green[600]! : Colors.green[500]!;
      case 2:
        return isDark ? Colors.green[500]! : Colors.green[300]!;
      case 1:
        return isDark ? Colors.green[400]! : Colors.green[200]!;
      default:
        return isDark ? Colors.grey[800]! : Colors.grey[200]!;
    }
  }

  void _previousMonth() {
    setState(() {
      _displayDate = DateTime(_displayDate.year, _displayDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayDate = DateTime(_displayDate.year, _displayDate.month + 1);
    });
  }

  void _onDayTap(DateTime date) {
    final fileName = DiaryDao.getDiaryFileName(date);

    // Check if diary exists for this day
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_characterCounts.containsKey(normalizedDate) && _characterCounts[normalizedDate]! > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiaryContentPage(fileName: fileName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarView),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics summary
                _buildStatisticsSummary(l10n),

                // Month navigation
                _buildMonthNavigation(),

                // Calendar heatmap
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildCalendarGrid(),
                    ),
                  ),
                ),

                // Legend
                _buildLegend(l10n),
              ],
            ),
    );
  }

  Widget _buildStatisticsSummary(AppLocalizations l10n) {
    final totalChars = _characterCounts.values.fold<int>(0, (sum, count) => sum + count);
    final totalDays = _characterCounts.length;
    final avgChars = totalDays > 0 ? (totalChars / totalDays).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(l10n.totalDays, totalDays.toString()),
          _buildStatItem(l10n.totalChars, totalChars.toString()),
          _buildStatItem(l10n.avgChars, avgChars.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    final monthYear = '${_displayDate.year}-${_displayDate.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            monthYear,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Calculate max count for color scaling
    final maxCount = _characterCounts.values.isEmpty
        ? 0
        : _characterCounts.values.reduce((a, b) => a > b ? a : b);

    // Get first day of the month
    final firstDay = DateTime(_displayDate.year, _displayDate.month, 1);
    final lastDay = DateTime(_displayDate.year, _displayDate.month + 1, 0);

    // Calculate starting offset (0 = Monday, 6 = Sunday)
    final startingWeekday = firstDay.weekday - 1;

    // Build grid
    final daysInMonth = lastDay.day;
    final totalCells = daysInMonth + startingWeekday;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Weekday headers
        _buildWeekdayHeaders(),
        const SizedBox(height: 8),

        // Calendar grid
        ...List.generate(rows, (rowIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (colIndex) {
                final cellIndex = rowIndex * 7 + colIndex;
                final dayNumber = cellIndex - startingWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return Expanded(child: Container(height: 40));
                }

                final date = DateTime(_displayDate.year, _displayDate.month, dayNumber);
                final normalizedDate = DateTime(date.year, date.month, date.day);
                final count = _characterCounts[normalizedDate] ?? 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onDayTap(date),
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _getColorForCount(count, maxCount),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          dayNumber.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                            color: count > 0 ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Less',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 8),
          ...List.generate(5, (index) {
            Color color;
            switch (index) {
              case 0:
                color = isDark ? Colors.grey[800]! : Colors.grey[200]!;
                break;
              case 1:
                color = isDark ? Colors.green[400]! : Colors.green[200]!;
                break;
              case 2:
                color = isDark ? Colors.green[500]! : Colors.green[300]!;
                break;
              case 3:
                color = isDark ? Colors.green[600]! : Colors.green[500]!;
                break;
              case 4:
                color = isDark ? Colors.green[700]! : Colors.green[700]!;
                break;
              default:
                color = Colors.grey;
            }

            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
          const SizedBox(width: 8),
          const Text(
            'More',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
