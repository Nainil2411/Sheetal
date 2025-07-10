import 'dart:developer';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/Screen/Sheetal/expense/expense.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/utils/firebase_service.dart';

class MonthlyComparisonCard extends StatefulWidget {
  final List<Invoice> invoices;
  final List<dynamic> collections;
  final List<Category> categories;

  const MonthlyComparisonCard({
    super.key,
    required this.invoices,
    required this.collections,
    required this.categories,
  });

  @override
  State<MonthlyComparisonCard> createState() => _MonthlyComparisonCardState();
}

class _MonthlyComparisonCardState extends State<MonthlyComparisonCard> {
  bool isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, double> currentMonthData = {
    'Revenue': 0.0,
    'Collection': 0.0,
    'Expense': 0.0,
    'Purchase': 0.0,
    'Profit': 0.0,
    'Net Profit': 0.0,
  };

  Map<String, double> previousMonthData = {
    'Revenue': 0.0,
    'Collection': 0.0,
    'Expense': 0.0,
    'Purchase': 0.0,
    'Profit': 0.0,
    'Net Profit': 0.0,
  };

  late DateTimeRange currentMonthRange;
  late DateTimeRange previousMonthRange;
  List<Purchase> purchases = [];
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _setupDateRanges();
    _loadData();
  }

  void _setupDateRanges() {
    final now = DateTime.now();

    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    currentMonthRange =
        DateTimeRange(start: currentMonthStart, end: currentMonthEnd);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    previousMonthRange =
        DateTimeRange(start: previousMonthStart, end: previousMonthEnd);
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final purchasesStream = _firebaseService.getPurchases();
      final expensesStream = _firebaseService.getSheetaLExpenses();
      final purchasesSnapshot = await purchasesStream.first;
      final expensesSnapshot = await expensesStream.first;

      purchases = purchasesSnapshot;
      expenses = expensesSnapshot;

      _processData();
    } catch (e) {
      log('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _processData() {
    try {
      _processRevenueData();
      _processCollectionData();
      _processExpenseData();
      _processPurchaseData();
      _calculateProfitData();
    } catch (e) {
      log('Error processing monthly comparison data: $e');
    }
  }

  void _processRevenueData() {
    double currentMonthRevenue = 0.0;
    double previousMonthRevenue = 0.0;

    final dateFormat = DateFormat('dd/MM/yyyy');
    for (var invoice in widget.invoices) {
      try {
        final invoiceDate = dateFormat.parse(invoice.date);

        if (_isInDateRange(invoiceDate, currentMonthRange)) {
          currentMonthRevenue += invoice.amount;
        } else if (_isInDateRange(invoiceDate, previousMonthRange)) {
          previousMonthRevenue += invoice.amount;
        }
      } catch (e) {
        log('Error parsing invoice date: ${invoice.date}');
      }
    }

    currentMonthData['Revenue'] = currentMonthRevenue;
    previousMonthData['Revenue'] = previousMonthRevenue;
  }

  void _processCollectionData() {
    double currentMonthCollection = 0.0;
    double previousMonthCollection = 0.0;

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (var collection in widget.collections) {
      try {
        final collectionDate = dateFormat.parse(collection.date);

        if (_isInDateRange(collectionDate, currentMonthRange)) {
          currentMonthCollection += collection.amount;
        } else if (_isInDateRange(collectionDate, previousMonthRange)) {
          previousMonthCollection += collection.amount;
        }
      } catch (e) {
        log('Error parsing collection date: ${collection.date}');
      }
    }

    currentMonthData['Collection'] = currentMonthCollection;
    previousMonthData['Collection'] = previousMonthCollection;
  }

  void _processExpenseData() {
    double currentMonthExpense = 0.0;
    double previousMonthExpense = 0.0;

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (var expense in expenses) {
      try {
        if (expense.expenseDate == null) continue;

        final expenseDate = dateFormat.parse(expense.expenseDate!);

        if (_isInDateRange(expenseDate, currentMonthRange)) {
          currentMonthExpense += expense.amount;
        } else if (_isInDateRange(expenseDate, previousMonthRange)) {
          previousMonthExpense += expense.amount;
        }
      } catch (e) {
        log('Error parsing expense date: ${expense.expenseDate}');
      }
    }
    currentMonthData['Expense'] = currentMonthExpense;
    previousMonthData['Expense'] = previousMonthExpense;
  }

  void _processPurchaseData() {
    double currentMonthPurchase = 0.0;
    double previousMonthPurchase = 0.0;

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (var purchase in purchases) {
      try {
        final purchaseDate = dateFormat.parse(purchase.date);

        if (_isInDateRange(purchaseDate, currentMonthRange)) {
          currentMonthPurchase += purchase.amount;
        } else if (_isInDateRange(purchaseDate, previousMonthRange)) {
          previousMonthPurchase += purchase.amount;
        }
      } catch (e) {
        log('Error parsing purchase date: ${purchase.date}');
      }
    }

    currentMonthData['Purchase'] = currentMonthPurchase;
    previousMonthData['Purchase'] = previousMonthPurchase;
  }

  void _calculateProfitData() {
    double currentMonthProfit =
        _calculateCategoryBasedProfit(currentMonthRange);
    double currentMonthNetProfit =
        currentMonthProfit - currentMonthData['Expense']!;
    double previousMonthProfit =
        _calculateCategoryBasedProfit(previousMonthRange);
    double previousMonthNetProfit =
        previousMonthProfit - previousMonthData['Expense']!;

    currentMonthData['Profit'] = currentMonthProfit;
    currentMonthData['Net Profit'] = currentMonthNetProfit;
    previousMonthData['Profit'] = previousMonthProfit;
    previousMonthData['Net Profit'] = previousMonthNetProfit;
  }

  double _calculateCategoryBasedProfit(DateTimeRange dateRange) {
    if (widget.categories.isEmpty || widget.invoices.isEmpty) {
      return 0.0;
    }

    double totalProfit = 0.0;
    Map<String, double> categoryRevenue = {};
    final dateFormat = DateFormat('dd/MM/yyyy');
    for (var invoice in widget.invoices) {
      try {
        final invoiceDate = dateFormat.parse(invoice.date);

        if (_isInDateRange(invoiceDate, dateRange)) {
          String categoryId = invoice.categoryId;
          categoryRevenue[categoryId] =
              (categoryRevenue[categoryId] ?? 0) + invoice.amount;
        }
      } catch (e) {
        log('Error parsing invoice date: ${invoice.date}');
      }
    }
    for (var category in widget.categories) {
      if (category.id != null && categoryRevenue.containsKey(category.id)) {
        double categoryAmount = categoryRevenue[category.id!]!;
        double categoryProfit = categoryAmount * (category.percentage / 100);
        totalProfit += categoryProfit;
      }
    }

    return totalProfit;
  }

  bool _isInDateRange(DateTime date, DateTimeRange range) {
    return (date.isAfter(range.start) || date.isAtSameMomentAs(range.start)) &&
        (date.isBefore(range.end) || date.isAtSameMomentAs(range.end));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getMonthComparisonTitle(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildComparisonChart(),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildComparisonTable(),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxAbsoluteValue() * 1.1,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final String metricName = _getMetricName(group.x);
                final double originalValue = rodIndex == 0
                    ? currentMonthData[metricName] ?? 0
                    : previousMonthData[metricName] ?? 0;
                return BarTooltipItem(
                  '₹${Global.formatAmount(originalValue)}',
                  const TextStyle(
                    color: CustomColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '\n$metricName',
                      style: const TextStyle(
                        color: CustomColors.background,
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\n${rodIndex == 0 ? 'Current Month' : 'Previous Month'}',
                      style: TextStyle(
                        color: rodIndex == 0
                            ? (originalValue < 0
                                ? Colors.redAccent
                                : Colors.greenAccent)
                            : (originalValue < 0
                                ? Colors.red
                                : Colors.orangeAccent),
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _getMetricName(value.toInt()),
                      style: const TextStyle(
                        color: CustomColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const Text('0', style: TextStyle(fontSize: 10));
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      _formatAxisValue(value),
                      style: const TextStyle(
                        color: CustomColors.textPrimary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 50,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: List.generate(6, (index) {
            final String metricName = _getMetricName(index);
            final double currentValue = currentMonthData[metricName] ?? 0;
            final double previousValue = previousMonthData[metricName] ?? 0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: currentValue.abs(),
                  color: currentValue < 0
                      ? CustomColors.error1
                      : CustomColors.textPrimary,
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: previousValue.abs(),
                  color: previousValue < 0
                      ? Colors.red.withOpacity(0.7)
                      : CustomColors.textSecondary,
                  width: 12,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getGridInterval(),
          ),
        ),
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value.abs() >= 1000000) {
      return '₹${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return '₹${value.toStringAsFixed(0)}';
    }
  }

  double _getGridInterval() {
    final maxValue = _getMaxAbsoluteValue();
    if (maxValue > 1000000) {
      return 500000;
    } else if (maxValue > 100000) {
      return 50000;
    } else if (maxValue > 10000) {
      return 10000;
    } else {
      return 5000;
    }
  }

  double _getMaxAbsoluteValue() {
    double maxCurrent = currentMonthData.values
        .map((v) => v.abs())
        .reduce((a, b) => a > b ? a : b);
    double maxPrevious = previousMonthData.values
        .map((v) => v.abs())
        .reduce((a, b) => a > b ? a : b);
    return maxCurrent > maxPrevious ? maxCurrent : maxPrevious;
  }

  Widget _buildComparisonTable() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'Metric',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Current',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Previous',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...currentMonthData.keys.map((metric) {
              final currentValue = currentMonthData[metric] ?? 0;
              final previousValue = previousMonthData[metric] ?? 0;
              final change = previousValue != 0
                  ? ((currentValue - previousValue) / previousValue * 100)
                  : (currentValue != 0 ? 100.0 : 0.0);
              final isPositive = change >= 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        metric,
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '₹${Global.formatAmount(currentValue)}',
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '₹${Global.formatAmount(previousValue)}',
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isPositive
                                ? CustomColors.green1
                                : CustomColors.error1,
                            size: 12,
                          ),
                          Text(
                            '${change.abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: isPositive
                                  ? CustomColors.green1
                                  : CustomColors.error1,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getMetricName(int index) {
    switch (index) {
      case 0:
        return 'Revenue';
      case 1:
        return 'Collection';
      case 2:
        return 'Expense';
      case 3:
        return 'Purchase';
      case 4:
        return 'Profit';
      case 5:
        return 'Net Profit';
      default:
        return '';
    }
  }

  String _getMonthComparisonTitle() {
    final currentMonth =
        DateFormat('MMMM yyyy').format(currentMonthRange.start);
    final previousMonth =
        DateFormat('MMMM yyyy').format(previousMonthRange.start);
    return '$currentMonth vs $previousMonth';
  }
}
