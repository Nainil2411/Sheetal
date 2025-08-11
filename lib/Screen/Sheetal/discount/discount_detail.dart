import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount_edit.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class DiscountDetailScreen extends StatefulWidget {
  final Discount discount;
  const DiscountDetailScreen({super.key, required this.discount});

  @override
  State<DiscountDetailScreen> createState() => _DiscountDetailScreenState();
}

class _DiscountDetailScreenState extends State<DiscountDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Discount _discount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _discount = widget.discount;
  }

  Future<void> _delete() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await _firebaseService.deleteDiscount(_discount.id!);
          if (mounted) Navigator.pop(context, true);
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _edit() async {
    final result = await Navigator.push<Discount>(
      context,
      MaterialPageRoute(
        builder: (context) => EditDiscountScreen(discount: _discount),
      ),
    );
    if (result != null) setState(() => _discount = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Discount Detail'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _isLoading ? null : _edit),
          IconButton(icon: const Icon(Icons.delete), onPressed: _isLoading ? null : _delete),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: DetailCard(
                amount: _discount.amount,
                isExpense: false,
                amountLabel: "Discount Amount",
                detailRows: [
                  DetailRow(label: 'Month', value: _discount.month),
                  if ((_discount.notes ?? '').isNotEmpty)
                    DetailRow(label: AppStrings.notes, value: _discount.notes!),
                ],
              ),
            ),
    );
  }
}


