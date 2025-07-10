import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_color.dart';

class MonthlyProfitData {
  final String month;
  final double profit;
  final double netProfit;
  final int year;
  final int monthNumber;

  MonthlyProfitData(
      this.month, this.profit, this.netProfit, this.year, this.monthNumber);
}

class MonthlyProfitCharts extends StatefulWidget {
  final List<Invoice> invoices;
  final List<dynamic> collections;
  final List<dynamic> expenses;
  final List<dynamic> purchases;
  final List<Category> categories;

  const MonthlyProfitCharts({
    super.key,
    required this.invoices,
    required this.collections,
    required this.expenses,
    required this.purchases,
    required this.categories,
  });

  @override
  State<MonthlyProfitCharts> createState() => _MonthlyProfitChartsState();
}

class _MonthlyProfitChartsState extends State<MonthlyProfitCharts> {
  List<MonthlyProfitData> monthlyData = [];
  String currentFinancialYear = '';

  @override
  void initState() {
    super.initState();
    _calculateMonthlyData();
  }

  @override
  void didUpdateWidget(MonthlyProfitCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.invoices != widget.invoices ||
        oldWidget.collections != widget.collections ||
        oldWidget.expenses != widget.expenses ||
        oldWidget.categories != widget.categories) {
      _calculateMonthlyData();
    }
  }

  void _calculateMonthlyData() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    int financialYearStart;
    if (now.month >= 4) {
      financialYearStart = now.year;
    } else {
      financialYearStart = now.year - 1;
    }

    currentFinancialYear =
        'Financial Year $financialYearStart-${financialYearStart + 1}';
    Map<String, MonthlyProfitData> monthlyMap = {};
    final months = [
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
      'Jan',
      'Feb',
      'Mar'
    ];

    for (int i = 0; i < months.length; i++) {
      int year = financialYearStart;
      int monthNum = i + 4;
      if (monthNum > 12) {
        monthNum -= 12;
        year += 1;
      }

      String key = '$year-${monthNum.toString().padLeft(2, '0')}';
      monthlyMap[key] = MonthlyProfitData(months[i], 0.0, 0.0, year, monthNum);
    }

    Map<String, double> monthlyRevenue = {};
    Map<String, double> monthlyProfit = {};

    for (var invoice in widget.invoices) {
      try {
        final invoiceDate = dateFormat.parse(invoice.date);
        final key =
            '${invoiceDate.year}-${invoiceDate.month.toString().padLeft(2, '0')}';
        if (monthlyMap.containsKey(key)) {
          monthlyRevenue[key] = (monthlyRevenue[key] ?? 0) + invoice.amount;

          final category = widget.categories.firstWhere(
            (cat) => cat.id == invoice.categoryId,
            orElse: () => Category(id: '', name: '', percentage: 0),
          );

          double invoiceProfit = invoice.amount * (category.percentage / 100);
          monthlyProfit[key] = (monthlyProfit[key] ?? 0) + invoiceProfit;
        }
      } catch (e) {
        continue;
      }
    }
    Map<String, double> monthlyExpenses = {};
    for (var expense in widget.expenses) {
      try {
        if (expense.expenseDate != null && expense.expenseDate!.isNotEmpty) {
          final expenseDate = dateFormat.parse(expense.expenseDate!);
          final key =
              '${expenseDate.year}-${expenseDate.month.toString().padLeft(2, '0')}';

          if (monthlyMap.containsKey(key)) {
            monthlyExpenses[key] = (monthlyExpenses[key] ?? 0) + expense.amount;
          }
        }
      } catch (e) {
        continue;
      }
    }
    monthlyMap.forEach((key, data) {
      double profit = monthlyProfit[key] ?? 0.0;
      double expenses = monthlyExpenses[key] ?? 0.0;
      double netProfit = profit - expenses;

      monthlyMap[key] = MonthlyProfitData(
        data.month,
        profit,
        netProfit,
        data.year,
        data.monthNumber,
      );
    });
    setState(() {
      monthlyData = monthlyMap.values.toList();
      monthlyData.sort((a, b) {
        if (a.year != b.year) {
          return a.year.compareTo(b.year);
        }
        return a.monthNumber.compareTo(b.monthNumber);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: const Center(
          child: Text(
            'No data available for charts',
            style: TextStyle(fontSize: 16, color: CustomColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentFinancialYear,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Profit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildProfitChart(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Net Profit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buildNetProfitChart(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: monthlyData
                .map((data) => data.profit.abs())
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${Global.formatAmount(monthlyData[groupIndex].profit)}',
                const TextStyle(
                  color: CustomColors.background,
                  fontWeight: FontWeight.bold,
                ),
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
                if (value < 0 || value >= monthlyData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    monthlyData[value.toInt()].month,
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
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 3.0),
                  child: Text(
                    '₹${(value / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(
                      color: CustomColors.textPrimary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 40,
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
        barGroups: List.generate(monthlyData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: monthlyData[index].profit.abs(),
                color: monthlyData[index].profit < 0
                    ? CustomColors.error1
                    : CustomColors.textPrimary,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20000,
        ),
      ),
    );
  }

  Widget _buildNetProfitChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: monthlyData
                .map((data) => data.netProfit.abs())
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${Global.formatAmount(monthlyData[groupIndex].netProfit)}',
                const TextStyle(
                  color: CustomColors.background,
                  fontWeight: FontWeight.bold,
                ),
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
                if (value < 0 || value >= monthlyData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    monthlyData[value.toInt()].month,
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
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '₹${(value / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(
                      color: CustomColors.textPrimary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 40,
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
        barGroups: List.generate(monthlyData.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: monthlyData[index].netProfit.abs(),
                color: monthlyData[index].netProfit < 0
                    ? CustomColors.error1
                    : CustomColors.textPrimary.withOpacity(0.6),
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20000,
        ),
      ),
    );
  }
}
