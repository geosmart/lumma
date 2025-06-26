import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/mermaid_widget.dart';

/// 支持 mermaid 代码块的 markdown 渲染组件
class EnhancedMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet? styleSheet;
  final EdgeInsets? padding;
  const EnhancedMarkdown({super.key, required this.data, this.styleSheet, this.padding});

  @override
  Widget build(BuildContext context) {
    final blocks = _splitMarkdownWithMermaid(data);
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: blocks.map((b) {
          if (b['type'] == 'mermaid') {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 180,
                child: MermaidWidget(mermaidSource: b['content']!),
              ),
            );
          } else {
            return MarkdownBody(
              data: b['content']!,
              styleSheet: styleSheet,
            );
          }
        }).toList(),
      ),
    );
  }

  /// 拆分 markdown 内容为普通块和 mermaid 块
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
