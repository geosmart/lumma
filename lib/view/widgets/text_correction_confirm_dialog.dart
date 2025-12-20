/// 纠错结果确认对话框
/// 显示纠错前后对比，用户可以选择接受、重试或取消
library;

import 'package:flutter/material.dart';
import '../../util/json_stream_parser.dart';

/// 纠错确认结果
enum CorrectionAction {
  accept, // 接受
  retry, // 重试
  cancel, // 取消
}

/// 纠错结果确认对话框
class TextCorrectionConfirmDialog extends StatelessWidget {
  final String originalText;
  final String correctedText;
  final List<CorrectionSegment>? segments;

  const TextCorrectionConfirmDialog({
    Key? key,
    required this.originalText,
    required this.correctedText,
    this.segments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 关闭按钮
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12),
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 24),
                  onPressed: () =>
                      Navigator.of(context).pop(CorrectionAction.cancel),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),

            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 纠错后的文本（带高亮）
                    _buildCorrectedTextView(context, isDark),

                    const SizedBox(height: 16),

                    // AI完成指令提示（优化后的版本）
                    _buildCompletionBanner(context, isDark),

                    const SizedBox(height: 12),

                    // 变更摘要（优化后的版本）
                    if (segments != null && segments!.isNotEmpty)
                      _buildChangeSummary(context, isDark),
                  ],
                ),
              ),
            ),

            // 底部按钮
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(CorrectionAction.accept),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.purple.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.purple.shade400),
                          const SizedBox(width: 8),
                          Text(
                            '接受',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.purple.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(CorrectionAction.cancel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(CorrectionAction.retry),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.purple.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.refresh, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            '重试',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建纠错后的文本视图（带高亮）
  Widget _buildCorrectedTextView(BuildContext context, bool isDark) {
    final normalColor = isDark ? Colors.white.withOpacity(0.87) : Colors.black87;
    final deleteColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final insertColor = isDark ? const Color(0xFFCE93D8) : const Color(0xFFBA68C8);

    if (segments == null || segments!.isEmpty) {
      // 没有片段数据，直接显示纠错后的文本
      return Text(
        correctedText,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: normalColor,
        ),
      );
    }

    final spans = <InlineSpan>[];

    for (final segment in segments!) {
      final before = segment.before;
      final after = segment.after;
      final type = segment.type;

      if (type == '删除') {
        // 删除：只显示删除线的原文（灰色）
        if (before.isNotEmpty) {
          spans.add(TextSpan(
            text: before,
            style: TextStyle(
              color: deleteColor,
              decoration: TextDecoration.lineThrough,
              decorationColor: deleteColor,
            ),
          ));
        }
      } else if (type == '纠正') {
        // 纠正：只显示修改后的文本（紫色高亮）
        if (before != after && after.isNotEmpty) {
          spans.add(TextSpan(
            text: after,
            style: TextStyle(
              color: insertColor,
              fontWeight: FontWeight.w500,
            ),
          ));
        } else {
          // before和after相同，正常显示
          spans.add(TextSpan(
            text: after,
            style: TextStyle(color: normalColor),
          ));
        }
      } else if (type == '不变') {
        // 不变：正常显示
        spans.add(TextSpan(
          text: after,
          style: TextStyle(color: normalColor),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: normalColor,
        ),
        children: spans,
      ),
    );
  }

  /// 构建完成横幅（优化版：减小高度和字体）
  Widget _buildCompletionBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.purple.shade900.withOpacity(0.3)
            : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.purple.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'AI 已完成指令',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.purple.shade200
                  : Colors.purple.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建变更摘要（优化版：使用适配深浅色主题的文字颜色）
  Widget _buildChangeSummary(BuildContext context, bool isDark) {
    final corrections = <String>[];
    final deletions = <String>[];

    for (final segment in segments!) {
      if (segment.type == '纠正' && segment.before != segment.after) {
        corrections.add('"${segment.before}" → "${segment.after}"');
      } else if (segment.type == '删除' && segment.before.isNotEmpty) {
        deletions.add('"${segment.before}"');
      }
    }

    final summaryItems = <Widget>[];

    // 错别字修正
    if (corrections.isNotEmpty) {
      summaryItems.add(_buildSummaryItem(
        context,
        isDark,
        '错别字修正：',
        corrections.take(3).join('，'),
      ));
    }

    // 冗余表达删减
    if (deletions.isNotEmpty) {
      summaryItems.add(_buildSummaryItem(
        context,
        isDark,
        '冗余表达删减：',
        '删除 ${deletions.take(3).join('、')}',
      ));
    }

    if (summaryItems.isEmpty) {
      summaryItems.add(_buildSummaryItem(
        context,
        isDark,
        '文本优化：',
        '已对文本进行优化处理',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaryItems,
    );
  }

  /// 构建摘要项（优化版：使用适配主题的文字颜色）
  Widget _buildSummaryItem(
    BuildContext context,
    bool isDark,
    String title,
    String content,
  ) {
    final textColor = isDark ? Colors.white.withOpacity(0.87) : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.purple.shade400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: textColor,
                ),
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
