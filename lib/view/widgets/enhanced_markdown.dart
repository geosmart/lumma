import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lumma/view/widgets/mermaid_widget.dart';
import 'package:lumma/service/theme_service.dart';

/// Markdown rendering component that supports mermaid code blocks
class EnhancedMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;
  final EdgeInsets? padding;
  const EnhancedMarkdown({super.key, required this.data, this.styleSheet, this.padding});

  @override
  Widget build(BuildContext context) {
    final blocks = _splitMarkdownWithMermaid(data);
    final theme = Theme.of(context);
    final defaultStyleSheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      p: theme.textTheme.bodyMedium?.copyWith(color: context.primaryTextColor),
      code: theme.textTheme.bodySmall?.copyWith(
        color: context.secondaryTextColor,
        backgroundColor: theme.colorScheme.surface,
      ),
      strong: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: context.primaryTextColor),
      blockquote: theme.textTheme.bodyMedium?.copyWith(color: context.secondaryTextColor.withOpacity(0.8)),
      h1: theme.textTheme.headlineLarge?.copyWith(color: context.primaryTextColor),
      h2: theme.textTheme.headlineMedium?.copyWith(color: context.primaryTextColor),
      h3: theme.textTheme.headlineSmall?.copyWith(color: context.primaryTextColor),
      h4: theme.textTheme.titleLarge?.copyWith(color: context.primaryTextColor),
      h5: theme.textTheme.titleMedium?.copyWith(color: context.primaryTextColor),
      h6: theme.textTheme.titleSmall?.copyWith(color: context.primaryTextColor),
      em: theme.textTheme.bodyMedium?.copyWith(color: context.secondaryTextColor, fontStyle: FontStyle.italic),
      listBullet: theme.textTheme.bodyMedium?.copyWith(color: context.primaryTextColor),
    );
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: blocks.map((b) {
          if (b['type'] == 'mermaid') {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(height: 180, child: MermaidWidget(mermaidSource: b['content']!)),
            );
          } else {
            return MarkdownBody(
              data: b['content']!,
              styleSheet: styleSheet ?? defaultStyleSheet,
              selectable: true,
            );
          }
        }).toList(),
      ),
    );
  }

  /// Split markdown content into normal blocks and mermaid blocks
  List<Map<String, String>> _splitMarkdownWithMermaid(String src) {
    final List<Map<String, String>> result = [];
    final reg = RegExp(r'```mermaid([\s\S]*?)```', multiLine: true);
    int last = 0;
    for (final m in reg.allMatches(src)) {
      if (m.start > last) {
        result.add({'type': 'md', 'content': src.substring(last, m.start)});
      }
      result.add({'type': 'mermaid', 'content': m.group(1)!.trim()});
      last = m.end;
    }
    if (last < src.length) {
      result.add({'type': 'md', 'content': src.substring(last)});
    }
    return result;
  }
}
