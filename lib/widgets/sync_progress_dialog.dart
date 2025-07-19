import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';

class SyncProgressDialog extends StatefulWidget {
  final int current;
  final int total;
  final String currentFile;
  final String currentStage;
  final List<String> logs;
  final bool isDone;
  final VoidCallback? onClose;

  const SyncProgressDialog({
    super.key,
    required this.current,
    required this.total,
    required this.currentFile,
    this.currentStage = '',
    this.logs = const [],
    this.isDone = false,
    this.onClose,
  });

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _lastValue = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _lastValue = widget.total > 0 ? widget.current / widget.total : 0;
  }

  @override
  void didUpdateWidget(covariant SyncProgressDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = widget.total > 0 ? widget.current / widget.total : 0.0;
    if (newValue != _lastValue) {
      _animation = Tween<double>(
        begin: _lastValue,
        end: newValue.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
      _lastValue = newValue.toDouble();
    }

    // 新日志添加时自动滚动到底部（append）
    if (widget.logs.length > oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.syncDialogTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LinearProgressIndicator(value: _animation.value, minHeight: 8);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.syncDialogProgress(
                  widget.current > widget.total ? widget.total : widget.current,
                  widget.total,
                )),
                if (widget.currentStage.isNotEmpty)
                  Text(widget.currentStage, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.currentFile,
                    style: TextStyle(
                      fontWeight: widget.currentFile.contains('[无变化]')
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: widget.currentFile.contains('[无变化]')
                          ? Colors.grey
                          : (widget.currentFile.contains('[新文件]')
                              ? Colors.blue
                              : (widget.currentFile.contains('[已变更]')
                                  ? Colors.orange
                                  : const Color.fromARGB(255, 95, 91, 96))),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.syncDialogLogs, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: widget.logs.length,
                  itemBuilder: (context, index) {
                    final logIndex = index + 1;
                    final log = widget.logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('$logIndex. $log', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (widget.onClose != null) widget.onClose!();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                  child: Text(l10n.commonClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
