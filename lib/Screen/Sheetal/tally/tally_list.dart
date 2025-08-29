import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/Screen/Sheetal/tally/tally_review.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/range_date_picker.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/common/export_utility.dart';

class TallyListScreen extends StatefulWidget {
  const TallyListScreen({super.key});

  @override
  State<TallyListScreen> createState() => _TallyListScreenState();
}

class _TallyListScreenState extends State<TallyListScreen> {
  final FirebaseService _firebase = FirebaseService();
  List<Invoice> _invoices = [];
  List<Collection> _collections = [];
  bool _loading = true;
  DateTimeRange? _selectedDateRange;

  // Data for the table
  List<TallyRowData> _tableData = [];
  TallyTotals _totals = TallyTotals.empty();

  @override
  void initState() {
    super.initState();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    _selectedDateRange = DateTimeRange(
      start: DateTime(yesterday.year, yesterday.month, yesterday.day),
      end: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _firebase.getInvoices().listen((inv) {
        setState(() => _invoices = inv);
        _prepareTableData();
      });
      _firebase.getCollections().listen((col) {
        setState(() => _collections = col);
        _prepareTableData();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return CustomDateRangePicker(initialDateRange: _selectedDateRange);
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedDateRange = result;
        _prepareTableData();
      });
    }
  }

  bool _isInDateRange(String dateString) {
    if (_selectedDateRange == null) return true;
    try {
      final dateFormat = DateFormat("dd/MM/yyyy");
      final date = dateFormat.parse(dateString);
      final endDate = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23, 59, 59,
      );
      return (date.isAfter(_selectedDateRange!.start) || date.isAtSameMomentAs(_selectedDateRange!.start)) &&
          (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
    } catch (e) {
      return true;
    }
  }

  Future<void> _prepareTableData() async {
    final invoicesByDate = <String, List<Invoice>>{};
    final collectionsByDate = <String, List<Collection>>{};

    // Group data by date
    for (final inv in _invoices) {
      invoicesByDate.putIfAbsent(inv.date, () => []).add(inv);
    }
    for (final c in _collections) {
      collectionsByDate.putIfAbsent(c.date, () => []).add(c);
    }

    // Get filtered dates
    final allDates = <String>{};
    allDates.addAll(invoicesByDate.keys);
    allDates.addAll(collectionsByDate.keys);

    final filteredDates = allDates.where((date) => _isInDateRange(date)).toList()
      ..sort((a, b) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        return dateFormat.parse(a).compareTo(dateFormat.parse(b));
      });

    // Prepare table data
    List<TallyRowData> tableData = [];
    double totalAmount = 0, totalCash = 0, totalOnline = 0, totalCheque = 0, totalOther = 0;

    for (final date in filteredDates) {
      final invoices = invoicesByDate[date] ?? [];
      final cols = collectionsByDate[date] ?? [];

      if (invoices.isEmpty && cols.isEmpty) continue;

      // Group by customer
      final customerData = await _processCustomerData(date, invoices, cols);

      for (final data in customerData) {
        tableData.add(data);
        totalAmount += data.amount;
        totalCash += data.cash;
        totalOnline += data.online;
        totalCheque += data.cheque;
        totalOther += data.other;
      }
    }

    setState(() {
      _tableData = tableData;
      _totals = TallyTotals(totalAmount, totalCash, totalOnline, totalCheque, totalOther);
    });
  }

  Future<List<TallyRowData>> _processCustomerData(String date, List<Invoice> invoices, List<Collection> collections) async {
    final Map<String, double> invoiceAmountByCustomer = {};
    final Map<String, double> cashByCustomer = {};
    final Map<String, double> onlineByCustomer = {};
    final Map<String, double> chequeByCustomer = {};
    final Map<String, double> otherByCustomer = {};

    // Process invoices
    for (final inv in invoices) {
      invoiceAmountByCustomer[inv.customerName] = (invoiceAmountByCustomer[inv.customerName] ?? 0) + inv.amount;
    }

    // Process collections
    for (final c in collections) {
      final mode = c.paymentMode.toLowerCase();
      final name = c.customerName;
      switch (mode) {
        case 'cash':
          cashByCustomer[name] = (cashByCustomer[name] ?? 0) + c.amount;
          break;
        case 'upi':
        case 'card':
        case 'bank transfer':
          onlineByCustomer[name] = (onlineByCustomer[name] ?? 0) + c.amount;
          break;
        case 'cheque':
          chequeByCustomer[name] = (chequeByCustomer[name] ?? 0) + c.amount;
          break;
        default:
          otherByCustomer[name] = (otherByCustomer[name] ?? 0) + c.amount;
      }
    }

    // Get approval status
    final approvalData = await _firebase.getDepositApprovalByDate(date);
    final cashApproved = approvalData?['cashApproved'] == true;
    final onlineApproved = approvalData?['onlineApproved'] == true;

    // Combine all customers
    final customers = invoiceAmountByCustomer.keys.toSet()
      ..addAll(cashByCustomer.keys)
      ..addAll(onlineByCustomer.keys)
      ..addAll(chequeByCustomer.keys)
      ..addAll(otherByCustomer.keys);

    return customers.map((name) => TallyRowData(
      date: date,
      customer: name,
      amount: invoiceAmountByCustomer[name] ?? 0,
      cash: cashByCustomer[name] ?? 0,
      online: onlineByCustomer[name] ?? 0,
      cheque: chequeByCustomer[name] ?? 0,
      other: otherByCustomer[name] ?? 0,
      cashApproved: cashApproved,
      onlineApproved: onlineApproved,
    )).toList();
  }

  Future<bool> _hasUnapprovedTransactions(List<String> filteredDates) async {
    final collectionsByDate = <String, List<Collection>>{};
    for (final c in _collections) {
      collectionsByDate.putIfAbsent(c.date, () => []).add(c);
    }

    for (final date in filteredDates) {
      final approvalData = await _firebase.getDepositApprovalByDate(date);
      final cols = collectionsByDate[date] ?? [];

      for (final collection in cols) {
        final paymentMode = collection.paymentMode.toLowerCase();
        if (['cash', 'upi', 'card', 'bank transfer', 'cheque', 'others'].contains(paymentMode)) {
          final isCash = paymentMode == 'cash';
          if (isCash && approvalData?['cashApproved'] == null) return true;
          if (!isCash && approvalData?['onlineApproved'] == null) return true;
        }
      }
    }
    return false;
  }

  bool _hasDepositsToReview() {
    return _tableData.any((row) =>
    (row.cash > 0) ||
        (row.online > 0) ||
        (row.cheque > 0) ||
        (row.other > 0)
    );
  }

  Future<void> _exportTallyToExcel(BuildContext context) async {
    String? dateRangeText;
    if (_selectedDateRange != null) {
      dateRangeText = '${DateFormat("dd/MM/yyyy").format(_selectedDateRange!.start)} - ${DateFormat("dd/MM/yyyy").format(_selectedDateRange!.end)}';
    }

    await ExportUtility.exportToExcel<TallyRowData>(
      context: context,
      data: _tableData,
      config: TallyExportConfig(),
      dateRangeText: dateRangeText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDates = _tableData.map((e) => e.date).toSet().toList();
    final hasDeposits = _hasDepositsToReview();

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Tally Sheet'),
        actions: [
          if (hasDeposits)
            IconButton(
              icon: const Icon(Icons.rate_review),
              onPressed: () {
                List<Collection> rangeCollections = [];
                for (final date in filteredDates) {
                  final cols = _collections.where((c) => c.date == date).toList();
                  rangeCollections.addAll(cols);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TallyReviewScreen(
                      dateRange: _selectedDateRange!,
                      collections: rangeCollections,
                    ),
                  ),
                ).then((_) => setState(() {}));
              },
              tooltip: 'Review Deposits',
            ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportTallyToExcel(context),
            tooltip: 'Export to Excel',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDateRangePicker,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _selectedDateRange != null
                  ? 'From ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} to ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                  : 'All Dates',
              style: AppTextStyles.labelLarge,
            ),
          ),
          Expanded(
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 12,
              minWidth: 900,
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.grey[100]!),
              headingTextStyle: AppTextStyles.labelLarge,
              dataTextStyle: TextStyle(
                fontSize: 14,
                color: CustomColors.textPrimary,
              ),
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              columns: const [
                DataColumn2(label: Text('Date'), size: ColumnSize.M),
                DataColumn2(label: Text('Customer'), size: ColumnSize.M),
                DataColumn2(label: Center(child: Text('Amount')), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Center(child: Text('Cash')), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Center(child: Text('UPI')), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Center(child: Text('Cheque')), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Center(child: Text('Others')), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Center(child: Text('Cash Dep.')), size: ColumnSize.S),
                DataColumn2(label: Center(child: Text('UPI Dep.')), size: ColumnSize.S),
              ],
              rows: [
                ..._tableData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final isEven = index % 2 == 0;

                  return DataRow2(
                    color: MaterialStateColor.resolveWith((states) =>
                    isEven ? Colors.white : Colors.grey.shade200),
                    cells: [
                      DataCell(Text(row.date)),
                      DataCell(Text(row.customer)),
                      DataCell(Center(child: Text('₹${Global.formatAmount(row.amount)}'))),
                      DataCell(Center(child: Text('₹${Global.formatAmount(row.cash)}'))),
                      DataCell(Center(child: Text('₹${Global.formatAmount(row.online)}'))),
                      DataCell(Center(child: Text('₹${Global.formatAmount(row.cheque)}'))),
                      DataCell(Center(child: Text('₹${Global.formatAmount(row.other)}'))),
                      DataCell(Center(child: Text(row.cashApproved ? '✔' : '-'))),
                      DataCell(Center(child: Text(row.onlineApproved ? '✔' : '-'))),
                    ],
                  );
                }),
                // Totals row
                DataRow2(
                  color: MaterialStateColor.resolveWith((states) => Colors.grey[100]!),
                  cells: [
                    const DataCell(Text('')),
                    DataCell(Text('Grand Total :', style: AppTextStyles.labelLarge)),
                    DataCell(Center(child: Text('₹${Global.formatAmount(_totals.amount)}', style: AppTextStyles.labelMedium))),
                    DataCell(Center(child: Text('₹${Global.formatAmount(_totals.cash)}', style: AppTextStyles.labelMedium))),
                    DataCell(Center(child: Text('₹${Global.formatAmount(_totals.online)}', style: AppTextStyles.labelMedium))),
                    DataCell(Center(child: Text('₹${Global.formatAmount(_totals.cheque)}', style: AppTextStyles.labelMedium))),
                    DataCell(Center(child: Text('₹${Global.formatAmount(_totals.other)}', style: AppTextStyles.labelMedium))),
                    const DataCell(Text('')),
                    const DataCell(Text('')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// Data models for better organization
class TallyRowData {
  final String date;
  final String customer;
  final double amount;
  final double cash;
  final double online;
  final double cheque;
  final double other;
  final bool cashApproved;
  final bool onlineApproved;

  TallyRowData({
    required this.date,
    required this.customer,
    required this.amount,
    required this.cash,
    required this.online,
    required this.cheque,
    required this.other,
    required this.cashApproved,
    required this.onlineApproved,
  });
}

class TallyTotals {
  final double amount;
  final double cash;
  final double online;
  final double cheque;
  final double other;

  TallyTotals(this.amount, this.cash, this.online, this.cheque, this.other);

  TallyTotals.empty() : amount = 0, cash = 0, online = 0, cheque = 0, other = 0;
}

class TallyExportConfig extends ExportConfig<TallyRowData> {
  @override
  String get title => 'Tally Sheet Report';

  @override
  String get fileName => 'tally_sheet_export';

  @override
  List<String> get headers => [
    'Sr. No.',
    'Date',
    'Customer',
    'Amount (₹)',
    'Cash (₹)',
    'UPI (₹)',
    'Cheque (₹)',
    'Others (₹)',
    'Cash Approved',
    'UPI Approved',
  ];

  @override
  bool get showTotal => true;

  @override
  int get amountColumnIndex => 3;

  @override
  List<dynamic> getRowData(TallyRowData tally) {
    return [
      '', // Sr. No. will be filled automatically
      tally.date,
      tally.customer,
      tally.amount,
      tally.cash,
      tally.online,
      tally.cheque,
      tally.other,
      tally.cashApproved ? 'Yes' : 'No',
      tally.onlineApproved ? 'Yes' : 'No',
    ];
  }

  @override
  double calculateTotal(List<TallyRowData> items) {
    return items.fold(0.0, (sum, tally) => sum + tally.amount);
  }
}
