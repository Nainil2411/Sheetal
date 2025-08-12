import 'package:flutter/material.dart';

class ExportProgressDialog extends StatefulWidget {
  final int totalItems;
  final ValueNotifier<int> currentProgressNotifier;
  final VoidCallback? onCancel;

  const ExportProgressDialog({
    super.key,
    required this.totalItems,
    required this.currentProgressNotifier,
    this.onCancel,
  });

  @override
  State<ExportProgressDialog> createState() => _ExportProgressDialogState();
}

class _ExportProgressDialogState extends State<ExportProgressDialog> {
  @override
  void dispose() {
    widget.currentProgressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Preparing Export'),
      content: ValueListenableBuilder<int>(
        valueListenable: widget.currentProgressNotifier,
        builder: (context, progress, _) {
          final int total = widget.totalItems == 0 ? 1 : widget.totalItems;
          final double percent = progress / total;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please wait while we prepare your Excel file...'),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: percent.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text('${(percent * 100).clamp(0, 100).round()}% Complete'),
              Text('Step $progress of $total'),
            ],
          );
        },
      ),
      actions: [
        if (widget.onCancel != null)
          TextButton(
            onPressed: widget.onCancel,
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}


