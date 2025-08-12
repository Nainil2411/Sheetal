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
import 'package:sheetal/common/export_utility.dart';
import 'package:sheetal/common/common_import.dart';
import 'package:sheetal/common/range_date_picker.dart';
import 'package:intl/intl.dart';

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
  DateTimeRange? _selectedDateRange;
  List<Expense> _lastExpenses = [];
  bool _isSelectionMode = false;
  final Set<String> _selectedExpenseIds = <String>{};

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
        title: Text(_isSelectionMode
            ? '${_selectedExpenseIds.length} selected'
            : AppStrings.expense),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelectedExpenses,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.filter_list, color: CustomColors.textPrimary),
                  onPressed: _showDateRangePicker,
                ),
              ],
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
          _lastExpenses = expenses;
          final filteredExpenses = expenses.where((expense) {
            final matchesText = expense.title.toLowerCase().contains(_searchText) ||
                expense.paymentMode.toLowerCase().contains(_searchText);
            final matchesDate = _isInDateRange(expense);
            return matchesText && matchesDate;
          }).toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: GenericListView<Expense>(
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
              // Selection wiring
              onItemLongPress: _enterSelectionMode,
              isSelectionMode: _isSelectionMode,
              selectedIds: _selectedExpenseIds,
              getId: (expense) => expense.id ?? '',
              onSelectionToggle: _toggleSelection,
              onSelectAll: _selectAllExpenses,
              onDeselectAll: _deselectAllExpenses,
            ),
          );
        },
      ),
      bottomSheet: _isSelectionMode
          ? null
          : BottomSheet(
        shape: Border.all(color: CustomColors.background),
        backgroundColor: CustomColors.background,
        onClosing: () {},
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              children: [
                // Import FAB
                FloatingActionButton(
                  heroTag: 'importExpenseFab',
                  onPressed: () => _importExpensesFromFile(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.upload_file, color: Colors.white),
                ),
                const SizedBox(width: 10),
                // Export FAB
                FloatingActionButton(
                  heroTag: 'exportExpenseFab',
                  onPressed: () => _exportExpensesToExcel(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.download, color: Colors.white),
                ),
                const SizedBox(width: 200),
                // Add Expense FAB
                CustomFAB(
                  heroTag: 'addExpenseFab',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddExpenseScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toggleSelection(Expense expense) {
    setState(() {
      if (expense.id == null) return;
      if (_selectedExpenseIds.contains(expense.id)) {
        _selectedExpenseIds.remove(expense.id);
        if (_selectedExpenseIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedExpenseIds.add(expense.id!);
      }
    });
  }

  void _enterSelectionMode(Expense expense) {
    if (expense.id == null) return;
    setState(() {
      _isSelectionMode = true;
      _selectedExpenseIds.add(expense.id!);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedExpenseIds.clear();
    });
  }

  void _selectAllExpenses() {
    setState(() {
      _selectedExpenseIds.clear();
      final visible = _lastExpenses.where((e) {
        final matchesText = e.title.toLowerCase().contains(_searchText) ||
            e.paymentMode.toLowerCase().contains(_searchText);
        final matchesDate = _isInDateRange(e);
        return matchesText && matchesDate;
      });
      for (final e in visible) {
        if (e.id != null) {
          _selectedExpenseIds.add(e.id!);
        }
      }
    });
  }

  void _deselectAllExpenses() {
    setState(() {
      _selectedExpenseIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedExpenses() async {
    if (_selectedExpenseIds.isEmpty) return;

    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        try {
          final success = await _firebaseService
              .deleteMultipleExpenses(_selectedExpenseIds.toList());
          if (success) {
            _exitSelectionMode();
          }
        } catch (_) {}
      },
    );
  }

  bool _isInDateRange(Expense expense) {
    if (_selectedDateRange == null) return true;

    final dateStr = expense.expenseDate;
    if (dateStr == null || dateStr.isEmpty) return false;

    try {
      final date = DateFormat('dd/MM/yyyy').parseStrict(dateStr);
      final endDate = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );
      return (date.isAfter(_selectedDateRange!.start) ||
              date.isAtSameMomentAs(_selectedDateRange!.start)) &&
          (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
    } catch (_) {
      return true;
    }
  }

  void _showDateRangePicker() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return CustomDateRangePicker(
          initialDateRange: _selectedDateRange,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedDateRange = result;
      });
    }
  }

  Future<void> _exportExpensesToExcel(BuildContext context) async {
    String? dateRangeText;
    if (_selectedDateRange != null) {
      dateRangeText = '${DateFormat("dd/MM/yyyy").format(_selectedDateRange!.start)} - ${DateFormat("dd/MM/yyyy").format(_selectedDateRange!.end)}';
    }

    // Use the last snapshot data to avoid waiting on the stream before showing progress
    final filtered = _lastExpenses.where((e) {
      final matchesText = e.title.toLowerCase().contains(_searchText) ||
          e.paymentMode.toLowerCase().contains(_searchText);
      final matchesDate = _isInDateRange(e);
      return matchesText && matchesDate;
    }).toList();

    await ExportUtility.exportToExcel<Expense>(
      context: context,
      data: filtered,
      config: ExportConfigs.expenseConfig,
      dateRangeText: dateRangeText,
    );
  }

  Future<void> _importExpensesFromFile(BuildContext context) async {
    await ImportUtility.importFromFile<Expense>(
      context: context,
      config: ImportConfigs.expenseConfig,
      onComplete: () {
        setState(() {});
      },
    );
  }
}
