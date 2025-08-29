import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount.dart';
import 'package:sheetal/Screen/Sheetal/credit/credit_edit.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class CreditDetailScreen extends StatefulWidget {
  final Discount credit;
  const CreditDetailScreen({super.key, required this.credit});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Discount _credit;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _credit = widget.credit;
  }

  Future<void> _delete() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() => _isLoading = true);
        try {
          await _firebaseService.deleteCredit(_credit.id!);
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
        builder: (context) => EditCreditScreen(credit: _credit),
      ),
    );
    if (result != null) setState(() => _credit = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Credit Detail'),
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
                amount: _credit.amount,
                isExpense: false,
                amountLabel: "Credit Amount",
                detailRows: [
                  DetailRow(label: 'Month', value: _credit.month),
                  if ((_credit.notes ?? '').isNotEmpty)
                    DetailRow(label: AppStrings.notes, value: _credit.notes!),
                ],
              ),
            ),
    );
  }
}


