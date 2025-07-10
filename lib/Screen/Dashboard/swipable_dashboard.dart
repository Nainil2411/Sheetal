import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Dashboard/Dashboard_card.dart';
import 'package:sheetal/Screen/Dashboard/expense_tracker.dart';
import 'package:sheetal/Screen/Dashboard/financial_overview.dart';
import 'package:sheetal/Screen/Dashboard/monthly_comparision.dart';
import 'package:sheetal/Screen/Dashboard/profit_chart.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/common/custom_color.dart';

class SwipableDashboardCards extends StatefulWidget {
  final double totalRevenue;
  final double totalCollection;
  final double totalExpenses;
  final double totalPurchase;
  final double profit;
  final double netProfit;
  final List<Invoice> invoices;
  final List<dynamic> collections;
  final List<dynamic> expenses;
  final List<dynamic> purchases;
  final List<Category> categories;
  final Function(int)? onPageChanged;

  const SwipableDashboardCards({
    super.key,
    required this.totalRevenue,
    required this.totalCollection,
    required this.totalExpenses,
    required this.totalPurchase,
    required this.profit,
    required this.netProfit,
    required this.invoices,
    required this.collections,
    required this.expenses,
    required this.purchases,
    required this.categories,
    this.onPageChanged,
  });

  @override
  State<SwipableDashboardCards> createState() => _SwipableDashboardCardsState();
}

class _SwipableDashboardCardsState extends State<SwipableDashboardCards> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double maxBudget = 1000000;
  double estimatedExpense = 600000;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    final currentMonthExpenses = widget.expenses.where((expense) {
      try {
        if (expense.expenseDate == null || expense.expenseDate!.isEmpty)
          return false;
        final parsedDate = dateFormatter.parse(expense.expenseDate!);
        return parsedDate.month == currentMonth &&
            parsedDate.year == currentYear;
      } catch (_) {
        return false;
      }
    }).toList();

    final double totalCurrentMonthExpense = currentMonthExpenses.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    return Column(
      children: [
        SizedBox(
          height: 600,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(index);
              }
            },
            children: [
              FinanceCardsPage(
                totalRevenue: widget.totalRevenue,
                totalCollection: widget.totalCollection,
                totalExpenses: widget.totalExpenses,
                totalPurchase: widget.totalPurchase,
                profit: widget.profit,
                netProfit: widget.netProfit,
              ),
              BubbleVisualization(
                totalRevenue: widget.totalRevenue,
                totalCollection: widget.totalCollection,
                totalExpenses: widget.totalExpenses,
                totalPurchase: widget.totalPurchase,
                profit: widget.profit,
                netProfit: widget.netProfit,
              ),
              MonthlyProfitCharts(
                invoices: widget.invoices,
                collections: widget.collections,
                expenses: widget.expenses,
                purchases: widget.purchases,
                categories: widget.categories,
              ),
              ExpenseTrackerCard(
                totalExpense: totalCurrentMonthExpense,
                estimatedExpense: estimatedExpense,
                initialMaxBudget: maxBudget,
              ),
              MonthlyComparisonCard(
                invoices: widget.invoices,
                collections: widget.collections,
                categories: widget.categories,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildPageIndicator(),
        const SizedBox(height: 30),
        const Divider(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? CustomColors.textPrimary
                : CustomColors.textPrimary.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
