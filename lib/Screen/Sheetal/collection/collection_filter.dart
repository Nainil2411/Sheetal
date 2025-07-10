import 'package:flutter/material.dart';

class PaymentModeFilterDialog extends StatefulWidget {
  final List<String> availablePaymentModes;
  final Set<String> selectedPaymentModes;

  const PaymentModeFilterDialog({
    super.key,
    required this.availablePaymentModes,
    required this.selectedPaymentModes,
  });

  @override
  State<PaymentModeFilterDialog> createState() =>
      _PaymentModeFilterDialogState();
}

class _PaymentModeFilterDialogState extends State<PaymentModeFilterDialog> {
  late Set<String> _tempSelectedModes;

  @override
  void initState() {
    super.initState();
    _tempSelectedModes = Set.from(widget.selectedPaymentModes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter by Payment Mode'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedModes.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedModes =
                          Set.from(widget.availablePaymentModes);
                    });
                  },
                  child: const Text('Select All'),
                ),
              ],
            ),
            const Divider(),
            ...widget.availablePaymentModes.map((mode) {
              return CheckboxListTile(
                title: Text(mode),
                value: _tempSelectedModes.contains(mode),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _tempSelectedModes.add(mode);
                    } else {
                      _tempSelectedModes.remove(mode);
                    }
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_tempSelectedModes),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
