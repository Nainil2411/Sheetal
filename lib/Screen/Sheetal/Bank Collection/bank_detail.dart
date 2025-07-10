import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank_edit.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class BankDetailScreen extends StatefulWidget {
  final Bank bank;
  const BankDetailScreen({super.key, required this.bank});

  @override
  State<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends State<BankDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Bank _bank;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bank = widget.bank;
  }

  Future<void> _deleteBank() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          await _firebaseService.deleteBank(_bank.id!);
          if (mounted) {
            Navigator.pop(context, true);
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }

  Future<void> _editBank() async {
    Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditBankScreen(bank: _bank),
      ),
    ).then((result) {
      if (result != null && result['success'] == true) {
        setState(() {
          _bank = result['bank'];
        });
      } else if (result != null && result['success'] == false) {
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Bank Collection Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editBank,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteBank,
          ),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: DetailCard(
          amount: _bank.total,
          isExpense: false,
          amountLabel: 'Total Collection',
          detailRows: [
            DetailRow(label: 'Date', value: _bank.selectedDate ?? 'No Date'),
            DetailRow(label: 'Invoice Total', value: '₹${Global.formatAmount(_bank.invoiceTotal)}'),
            DetailRow(label: 'Cash', value: '₹${Global.formatAmount(_bank.cash)}'),
            DetailRow(label: 'Online', value: '₹${Global.formatAmount(_bank.online)}'),
            DetailRow(label: 'Cheque', value: '₹${Global.formatAmount(_bank.cheque)}'),
            DetailRow(label: 'Others', value: '₹${Global.formatAmount(_bank.others)}'),
          ],
        ),
      ),
    );
  }
}
