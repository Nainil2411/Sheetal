import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Dashboard/swipable_dashboard.dart';
import 'package:sheetal/Screen/Sheetal/Homepage/pending_viewall.dart';
import 'package:sheetal/Screen/Sheetal/Homepage/pendingcollection_detail.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/range_date_picker.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class DashboardScreen extends StatefulWidget {
  final bool isInTabView;

  const DashboardScreen({super.key, this.isInTabView = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalRevenue = 0.0;
  double totalCollection = 0.0;
  double totalExpenses = 0.0;
  double scpl = 0.0;
  double profit = 0.0;
  double netProfit = 0.0;
  double totalPurchase = 0.0;
  double totalDiscount = 0.0;
  double totalScheme = 0.0;
  double totalCredit = 0.0;
  bool isLoading = true;
  List<Map<String, dynamic>> reminders = [];
  List<Category> categories = [];
  List<Invoice> invoices = [];
  List<dynamic> collections = [];
  List<dynamic> expenses = [];
  List<dynamic> purchases = [];
  List<dynamic> discounts = [];
  List<dynamic> schemes = [];
  List<dynamic> credits = [];
  final FirebaseService _firebaseService = FirebaseService();
  int _currentSwipePage = 0;

  DateTimeRange? _selectedDateRange;
  List<Invoice> _filteredInvoices = [];
  List<dynamic> _filteredCollections = [];
  List<dynamic> _filteredExpenses = [];
  List<dynamic> _filteredPurchases = [];
  List<dynamic> _filteredDiscounts = [];
  List<dynamic> _filteredSchemes = [];
  List<dynamic> _filteredCredits = [];

  String _getAppBarTitle() {
    switch (_currentSwipePage) {
      case 0:
        return AppStrings.dashboard;
      case 1:
        return 'Financial Overview';
      case 2:
        return 'Calculation';
      case 3:
        return 'Financial Performance';
      case 4:
        return 'Expense Summary';
      case 5:
        return 'Comparison Chart';
      default:
        return AppStrings.dashboard;
    }
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _currentSwipePage = pageIndex;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      _currentSwipePage = 0;
    });

    try {
      _firebaseService.getCategories().listen((categoryList) {
        setState(() {
          categories = categoryList;
          _applyDateFilter();
        });
      });

      _firebaseService.getInvoices().listen((invoiceList) {
        setState(() {
          invoices = invoiceList;
          _applyDateFilter();
        });
      });

      _firebaseService.getCollections().listen((collectionList) {
        setState(() {
          collections = collectionList;
          _applyDateFilter();
        });
      });

      _firebaseService.getSheetaLExpenses().listen((expenseList) {
        setState(() {
          expenses = expenseList;
          _applyDateFilter();
        });
      });

      _firebaseService.getPurchases().listen((purchaseList) {
        setState(() {
          purchases = purchaseList;
          _applyDateFilter();
        });
      });

      _firebaseService.getDiscounts().listen((discountList) {
        setState(() {
          discounts = discountList;
          _applyDateFilter();
        });
      });

      _firebaseService.getSchemes().listen((schemeList) {
        setState(() {
          schemes = schemeList;
          _applyDateFilter();
        });
      });

      _firebaseService.getCredits().listen((creditList) {
        setState(() {
          credits = creditList;
          _applyDateFilter();
        });
      });

      await _loadReminders();
    } catch (e) {
      log('Error loading dashboard data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyDateFilter() {
    if (_selectedDateRange == null) {
      _filteredInvoices = List.from(invoices);
      _filteredCollections = List.from(collections);
      _filteredExpenses = List.from(expenses);
      _filteredPurchases = List.from(purchases);
      _filteredDiscounts = List.from(discounts);
      _filteredSchemes = List.from(schemes);
      _filteredCredits = List.from(credits);
    } else {
      _filteredInvoices =
          invoices.where((invoice) => _isInDateRange(invoice.date)).toList();
      _filteredCollections = collections
          .where((collection) => _isInDateRange(collection.date))
          .toList();
      _filteredExpenses = expenses
          .where((expense) => _isInDateRange(expense.expenseDate ?? ''))
          .toList();
      _filteredPurchases = purchases
          .where((purchase) => _isInDateRange(purchase.date ?? ''))
          .toList();
      _filteredDiscounts = discounts
          .where((discount) => _isInDateRange(_coerceDiscountDateString(discount)))
          .toList();
      _filteredSchemes = schemes
          .where((scheme) => _isInDateRange(_coerceDiscountDateString(scheme)))
          .toList();
      _filteredCredits = credits
          .where((credit) => _isInDateRange(_coerceDiscountDateString(credit)))
          .toList();
    }
    _calculateFilteredTotals();
  }

  String _coerceDiscountDateString(dynamic discount) {
    // discount.month is 'MMMM yyyy' like 'September 2025'; treat as 1st of that month
    try {
      final monthStr = discount.month as String?;
      if (monthStr == null || monthStr.isEmpty) return '';
      final parsed = DateFormat('MMMM yyyy').parse(monthStr);
      return DateFormat('dd/MM/yyyy').format(DateTime(parsed.year, parsed.month, 1));
    } catch (_) {
      return '';
    }
  }

  void _calculateFilteredTotals() {
    double revenue = 0.0;
    for (var invoice in _filteredInvoices) {
      revenue += invoice.amount;
    }

    double collection = 0.0;
    for (var coll in _filteredCollections) {
      collection += coll.amount;
    }

    double expense = 0.0;
    for (var exp in _filteredExpenses) {
      expense += exp.amount;
    }

    double purchase = 0.0;
    for (var purch in _filteredPurchases) {
      purchase += purch.amount;
    }

    double discountSum = 0.0;
    for (var d in _filteredDiscounts) {
      discountSum += d.amount;
    }

    double schemeSum = 0.0;
    for (var s in _filteredSchemes) {
      schemeSum += s.amount;
    }

    double creditSum = 0.0;
    for (var c in _filteredCredits) {
      creditSum += c.amount;
    }

    setState(() {
      totalRevenue = revenue;
      totalCollection = collection;
      totalExpenses = expense;
      totalPurchase = purchase;
      totalDiscount = discountSum;
      totalScheme = schemeSum;
      totalCredit = creditSum;
      _calculateCategoryBasedProfit();
    });
  }

  bool _isInDateRange(String dateString) {
    if (_selectedDateRange == null || dateString.isEmpty) return true;

    try {
      final dateFormat = DateFormat('dd/MM/yyyy');
      final itemDate = dateFormat.parse(dateString);

      final endDate = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );

      return (itemDate.isAfter(_selectedDateRange!.start) ||
              itemDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
          (itemDate.isBefore(endDate) || itemDate.isAtSameMomentAs(endDate));
    } catch (e) {
      return false;
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
        _applyDateFilter();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _applyDateFilter();
    });
  }

  String _formatDate(DateTime date) {
    final dateFormat = DateFormat("dd/MM/yyyy");
    return dateFormat.format(date);
  }

  bool _shouldShowDateFilter() {
    return _currentSwipePage == 0 || _currentSwipePage == 1 || _currentSwipePage == 2;
  }

  void _calculateCategoryBasedProfit() {
    if (categories.isEmpty || _filteredInvoices.isEmpty) {
      profit = 0.0;
      _calculateNetProfit();
      return;
    }
    double totalProfit = 0.0;
    Map<String, double> categoryRevenue = {};

    for (var invoice in _filteredInvoices) {
      String categoryId = invoice.categoryId;
      categoryRevenue[categoryId] =
          (categoryRevenue[categoryId] ?? 0) + invoice.amount;
    }

    for (var category in categories) {
      if (category.id != null && categoryRevenue.containsKey(category.id)) {
        double categoryAmount = categoryRevenue[category.id!]!;
        double categoryProfit = categoryAmount * (category.percentage / 100);
        totalProfit += categoryProfit;
      }
    }

    setState(() {
      profit = totalProfit;
      _calculateNetProfit();
    });
  }

  void _calculateNetProfit() {
    // Net profit = profit - expenses (discount is visual only in bubble)
    netProfit = profit - totalExpenses;
  }

  Future<void> _loadReminders() async {
    try {
      final invoices = await _firebaseService.getInvoices().first;
      final collections = await _firebaseService.getCollections().first;

      Map<String, double> invoiceAmountByCustomer = {};
      Map<String, double> collectionAmountByCustomer = {};

      for (var invoice in invoices) {
        invoiceAmountByCustomer[invoice.customerName] =
            (invoiceAmountByCustomer[invoice.customerName] ?? 0) +
                invoice.amount;
      }

      for (var collection in collections) {
        collectionAmountByCustomer[collection.customerName] =
            (collectionAmountByCustomer[collection.customerName] ?? 0) +
                collection.amount;
      }

      List<Map<String, dynamic>> pendingReminders = [];
      invoiceAmountByCustomer.forEach((customer, invoiceAmount) {
        double collectionAmount = collectionAmountByCustomer[customer] ?? 0;
        double pendingAmount = invoiceAmount - collectionAmount;

        if (pendingAmount > 0) {
          pendingReminders.add({
            'customerName': customer,
            'pendingAmount': pendingAmount,
            'type': 'collection'
          });
        }
      });

      setState(() {
        reminders = pendingReminders;
      });
    } catch (e) {
      log('Error loading reminders: $e');
    }
  }

  void _navigateToAllPendingCollections() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllPendingCollectionsScreen(
          pendingCollections: reminders,
        ),
      ),
    );
    if (result == true) {
      _loadDashboardData();
    }
  }

  void _navigateToPendingCollectionDetail(Map<String, dynamic> reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PendingCollectionDetailScreen(
          pendingCollection: reminder,
        ),
      ),
    );
    if (result == true) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(_getAppBarTitle(), style: AppTextStyles.headline1),
        showLeadingIcon: false,
        actions: _shouldShowDateFilter()
            ? [
                IconButton(
                  icon: const Icon(Icons.filter_list,
                      color: CustomColors.textPrimary),
                  onPressed: _showDateRangePicker,
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: isLoading
            ? Utility.circleloading()
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                color: CustomColors.textPrimary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      if (_shouldShowDateFilter() && _selectedDateRange != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: Colors.grey[100],
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Filtered: ${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: CustomColors.textPrimary),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: _clearDateFilter,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      SwipableDashboardCards(
                        totalRevenue: totalRevenue,
                        totalCollection: totalCollection,
                        totalExpenses: totalExpenses,
                        totalPurchase: totalPurchase,
                        totalDiscount: totalDiscount,
                        totalScheme: totalScheme,
                        totalCredit: totalCredit,
                        profit: profit,
                        netProfit: netProfit,
                        invoices: invoices,
                        collections: collections,
                        expenses: expenses,
                        purchases: purchases,
                        categories: categories,
                        onPageChanged: _onPageChanged,
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.notifications, size: 30),
                                const Text(
                                  AppStrings.reminders,
                                  style: AppTextStyles.headline4,
                                ),
                                const Spacer(),
                                if (reminders.length > 3)
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed:
                                            _navigateToAllPendingCollections,
                                        child: const Text(
                                          AppStrings.viewall,
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 15,
                                        color: CustomColors.textPrimary,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildRemindersList(),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRemindersList() {
    if (reminders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(AppStrings.noreminders),
      );
    }
    final displayItems =
        reminders.length > 3 ? reminders.sublist(0, 3) : reminders;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final reminder = displayItems[index];
        return Card(
          elevation: 2,
          color: CustomColors.background,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => _navigateToPendingCollectionDetail(reminder),
            title: Text(reminder['customerName']),
            subtitle: Text('Pending Collection'),
            trailing: Text(
              '₹${Global.formatAmount(reminder['pendingAmount'])}',
              style: AppTextStyles.redtext,
            ),
          ),
        );
      },
    );
  }
}
