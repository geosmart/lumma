import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lumma/generated/l10n/app_localizations.dart';

class MermaidWidget extends StatefulWidget {
  final String mermaidSource;
  const MermaidWidget({super.key, required this.mermaidSource});

  @override
  State<MermaidWidget> createState() => _MermaidWidgetState();
}

class _MermaidWidgetState extends State<MermaidWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    final html =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    html, body { margin: 0; padding: 0; background: #f8f8f8; }
    #container { width: 100vw; min-height: 60px; }
  </style>
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
</head>
<body>
  <div id="container">
    <div class="mermaid">${const HtmlEscape().convert(widget.mermaidSource)}</div>
  </div>
  <script>
    mermaid.initialize({ startOnLoad: true });
  </script>
</body>
</html>
''';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Text(l10n.mermaidMobileOnly),
      );
    }
    try {
      return SizedBox(height: 180, child: WebViewWidget(controller: _controller));
    } catch (e) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
        child: Text('${l10n.mermaidRenderError}: \\n$e'),
      );
    }
  }
}
