import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:lumma/dao/diary_dao.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';
import 'package:lumma/view/routes/app_routes.dart';
import 'package:lumma/view/pages/diary_content_page.dart';

/// 列表视图：显示所有历史日记的时间线
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  final ScrollController _scrollController = ScrollController();
  final List<_DiaryEntryWithMeta> _allEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllDiaries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDiaries() async {
    setState(() => _isLoading = true);

    try {
      final diaryDir = await DiaryDao.getDiaryDir();
      final files = await DiaryDao.listDiaryFiles();

      final List<_DiaryEntryWithMeta> entries = [];

      // 读取所有日记文件
      for (final fileName in files) {
        try {
          final file = File('$diaryDir/$fileName');
          if (await file.exists()) {
            final content = await file.readAsString();
            final fileEntries = DiaryDao.parseDiaryContent(context, content);

            // 从文件名解析日期 (格式: YYYY-MM-DD.md)
            final dateStr = fileName.replaceAll('.md', '');
            DateTime? date;
            try {
              final parts = dateStr.split('-');
              if (parts.length == 3) {
                date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
              }
            } catch (e) {
              // 如果解析失败，使用文件修改时间
              date = await file.lastModified();
            }

            // 将每个条目包装为_DiaryEntryWithMeta
            for (final entry in fileEntries) {
              entries.add(_DiaryEntryWithMeta(entry: entry, date: date ?? DateTime.now(), fileName: fileName));
            }
          }
        } catch (e) {
          print('加载文件 $fileName 失败: $e');
        }
      }

      // 按日期降序排序（最新的在前）
      entries.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _allEntries.clear();
        _allEntries.addAll(entries);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return '今天';
    } else if (entryDate == yesterday) {
      return '昨天';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.cardBackgroundColor,
        elevation: 0.2,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.secondaryTextColor),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: '返回',
        ),
        title: Text(
          l10n.diaryTimelineListTitle,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.primaryTextColor),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: l10n.calendarView,
            onPressed: () => Get.toNamed(AppRoutes.diaryCalendar),
          ),
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: l10n.fileView,
            onPressed: () => Get.toNamed(AppRoutes.diaryFileList),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllDiaries),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 80, color: context.secondaryTextColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(l10n.noDiaryYet, style: TextStyle(fontSize: 16, color: context.secondaryTextColor)),
                ],
              ),
            )
          : Scrollbar(
              controller: _scrollController,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: _allEntries.length,
                itemBuilder: (ctx, i) {
                  final entryWithDate = _allEntries[i];
                  final entry = entryWithDate.entry;
                  final date = entryWithDate.date;

                  // 检查是否需要显示日期分隔符
                  bool showDateDivider = false;
                  if (i == 0) {
                    showDateDivider = true;
                  } else {
                    final prevDate = _allEntries[i - 1].date;
                    final prevDay = DateTime(prevDate.year, prevDate.month, prevDate.day);
                    final currentDay = DateTime(date.year, date.month, date.day);
                    if (prevDay != currentDay) {
                      showDateDivider = true;
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 日期分隔符
                      if (showDateDivider)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12, top: i == 0 ? 0 : 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  _formatDate(date),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.secondaryTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 时间线条目
                      GestureDetector(
                        onTap: () {
                          // 点击跳转到日记详情页
                          Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => DiaryContentPage(fileName: entryWithDate.fileName)));
                        },
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline indicator
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF4CAF50)
                                          : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  // 检查是否需要显示连接线
                                  if (i < _allEntries.length - 1) ...[
                                    // 扩展到内容底部
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white.withOpacity(0.2)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    // 延伸到下一个条目的间距中
                                    Container(
                                      width: 2,
                                      height: 16,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.grey.shade300,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 时间和标题
                                      Row(
                                        children: [
                                          if (entry.time != null && entry.time!.isNotEmpty)
                                            Text(
                                              entry.displayTime!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: context.secondaryTextColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          if (entry.time != null && entry.time!.isNotEmpty && entry.title.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(
                                                '·',
                                                style: TextStyle(fontSize: 12, color: context.secondaryTextColor),
                                              ),
                                            ),
                                          if (entry.title.isNotEmpty)
                                            Expanded(
                                              child: Text(
                                                entry.title,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: context.primaryTextColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // 日记内容
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          entry.q ?? '',
                                          style: TextStyle(fontSize: 15, color: context.primaryTextColor),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

/// 日记条目与元数据的组合（内部使用）
class _DiaryEntryWithMeta {
  final DiaryEntry entry;
  final DateTime date;
  final String fileName;

  _DiaryEntryWithMeta({required this.entry, required this.date, required this.fileName});
}
