import 'package:flutter/material.dart';

class ImportProgressDialog extends StatefulWidget {
  final int totalItems;
  final ValueNotifier<int> currentProgressNotifier;
  final VoidCallback? onCancel;

  const ImportProgressDialog({
    super.key,
    required this.totalItems,
    required this.currentProgressNotifier,
    this.onCancel,
  });

  @override
  State<ImportProgressDialog> createState() => _ImportProgressDialogState();
}

class _ImportProgressDialogState extends State<ImportProgressDialog> {
  @override
  void dispose() {
    widget.currentProgressNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importing Data'),
      content: ValueListenableBuilder<int>(
        valueListenable: widget.currentProgressNotifier,
        builder: (context, progress, _) {
          double percent = widget.totalItems == 0
              ? 0
              : progress / widget.totalItems;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please wait while we import your data...'),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text('${(percent * 100).round()}% Complete'),
              Text('Processing $progress of ${widget.totalItems} items'),
            ],
          );
        },
      ),
    );
  }
}
