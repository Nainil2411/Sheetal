import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/expense/editexpense_screen.dart';
import 'package:sheetal/Screen/Sheetal/expense/expense.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Expense _expense;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  Future<void> _deleteExpense() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          await _firebaseService.deleteSheetaLExpense(_expense.id!);
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

  Future<void> _editExpense() async {
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: _expense),
      ),
    );

    if (result != null) {
      setState(() {
        _expense = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.expensedetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editExpense,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteExpense,
          ),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: DetailCard(
                amount: _expense.amount,
                isExpense: true,
                amountLabel: AppStrings.amount,
                detailRows: [
                  DetailRow(label: AppStrings.expensename, value: _expense.title),
                  DetailRow(label: AppStrings.mode, value: _expense.paymentMode),
                  DetailRow(label: AppStrings.date, value: _expense.expenseDate!),
                ],
              ),
            ),
    );
  }
}