import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/expense/addexpense.dart';
import 'package:sheetal/Screen/Sheetal/expense/expense.dart';
import 'package:sheetal/Screen/Sheetal/expense/expensedetail_screen.dart';
import 'package:sheetal/utils/firebase_service.dart';

import 'package:sheetal/utils/utility.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String _searchText = '';
  Stream<List<Expense>>? _expensesStream;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _expensesStream = _firebaseService.getSheetaLExpenses();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.expense),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _expensesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Utility.circleloading();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(AppStrings.genericError + snapshot.error.toString()),
            );
          }

          List<Expense> expenses = snapshot.data ?? [];
          final filteredExpenses = expenses.where((expense) {
            return expense.title.toLowerCase().contains(_searchText) ||
                expense.paymentMode.toLowerCase().contains(_searchText);
          }).toList();

          return GenericListView<Expense>(
            items: filteredExpenses,
            isLoading: false,
            emptyMessage: AppStrings.noExpenseFound,
            searchController: _searchController,
            onSearch: (text) {
              setState(() {
                _searchText = text.toLowerCase();
              });
            },
            searchText: _searchText,
            getTitle: (expense) => expense.title,
            getAmount: (expense) => '₹${Global.formatAmount(expense.amount)}',
            getAmountColor: (expense) => CustomColors.error,
            getSubtitle: (expense) => expense.expenseDate,
            getInitials: (expense) => expense.title.isNotEmpty
                ? expense.title.substring(0, min(2, expense.title.length)).toUpperCase()
                : '',
            getDateString: (expense) => expense.expenseDate,
            enableSorting: true,
            sortAscending: _sortAscending,
            onSortChanged: (ascending) {
              setState(() {
                _sortAscending = ascending;
              });
            },
            onItemTap: (expense) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExpenseDetailScreen(expense: expense),
                ),
              );
              if (result == true) {
              }
            },
          );
        },
      ),
      floatingActionButton: CustomFAB(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
      ),
    );
  }
}
