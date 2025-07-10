import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';

import '../../common/custom_appbar.dart';
import '../../common/custom_color.dart';
import '../../utils/firebase_service.dart';
import '../../utils/utility.dart';

class CustomerInvoiceHistoryScreen extends StatefulWidget {
  const CustomerInvoiceHistoryScreen({super.key});

  @override
  State<CustomerInvoiceHistoryScreen> createState() =>
      _CustomerInvoiceHistoryScreenState();
}

class _CustomerInvoiceHistoryScreenState
    extends State<CustomerInvoiceHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = true;
  bool hasData = false;

  List<String> allCustomerNames = [];
  String? selectedCustomer1;
  String? selectedCustomer2;

  Map<String, List<Invoice>> customer1MonthlyInvoices = {};
  Map<String, double> customer1MonthlyTotals = {};
  Map<String, List<Invoice>> customer2MonthlyInvoices = {};
  Map<String, double> customer2MonthlyTotals = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeCustomers();
  }

  Future<void> _initializeCustomers() async {
    try {
      final invoices = await _firebaseService.getInvoices().first;
      final names = invoices.map((e) => e.customerName).toSet().toList();
      names.sort();

      final prefs = await SharedPreferences.getInstance();
      final savedCustomer1 = prefs.getString('selectedCustomer1');
      final savedCustomer2 = prefs.getString('selectedCustomer2');

      setState(() {
        allCustomerNames = names;
        hasData = names.isNotEmpty;

        if (names.length >= 2) {
          if (savedCustomer1 != null &&
              savedCustomer2 != null &&
              names.contains(savedCustomer1) &&
              names.contains(savedCustomer2) &&
              savedCustomer1 != savedCustomer2) {
            selectedCustomer1 = savedCustomer1;
            selectedCustomer2 = savedCustomer2;
          } else {
            selectedCustomer1 = names[0];
            selectedCustomer2 = names[1];
            _saveCustomerSelection();
          }
        }
      });

      if (names.length >= 2) {
        await _loadInvoiceData();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      log('Error initializing customers: $e');
      setState(() {
        isLoading = false;
        hasData = false;
      });
    }
  }

  Future<void> _saveCustomerSelection() async {
    final prefs = await SharedPreferences.getInstance();
    if (selectedCustomer1 != null) {
      await prefs.setString('selectedCustomer1', selectedCustomer1!);
    }
    if (selectedCustomer2 != null) {
      await prefs.setString('selectedCustomer2', selectedCustomer2!);
    }
  }

  Future<void> _loadInvoiceData() async {
    if (selectedCustomer1 == null || selectedCustomer2 == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      await Future.wait([
        _loadInvoicesForCustomer(selectedCustomer1!, isFirstCustomer: true),
        _loadInvoicesForCustomer(selectedCustomer2!, isFirstCustomer: false),
      ]);
    } catch (e) {
      log('Error loading invoice data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadInvoicesForCustomer(String customerName,
      {required bool isFirstCustomer}) async {
    try {
      final allInvoices = await _firebaseService.getInvoices().first;
      final customerInvoices = allInvoices
          .where(
              (i) => i.customerName.toLowerCase() == customerName.toLowerCase())
          .toList();

      Map<String, List<Invoice>> monthlyInvoices = {};
      Map<String, double> monthlyTotals = {};

      for (var invoice in customerInvoices) {
        DateTime invoiceDate;
        try {
          invoiceDate = DateFormat('dd/MM/yyyy').parse(invoice.date);
        } catch (_) {
          invoiceDate = invoice.createdAt.toDate();
        }
        String monthKey = DateFormat('MMMM yyyy').format(invoiceDate);

        monthlyInvoices.putIfAbsent(monthKey, () => []);
        monthlyTotals.putIfAbsent(monthKey, () => 0.0);

        monthlyInvoices[monthKey]!.add(invoice);
        monthlyTotals[monthKey] = monthlyTotals[monthKey]! + invoice.amount;
      }

      final sortedKeys = monthlyInvoices.keys.toList()
        ..sort((a, b) => DateFormat('MMMM yyyy')
            .parse(b)
            .compareTo(DateFormat('MMMM yyyy').parse(a)));

      Map<String, List<Invoice>> sortedMonthlyInvoices = {};
      Map<String, double> sortedMonthlyTotals = {};
      for (var key in sortedKeys) {
        sortedMonthlyInvoices[key] = monthlyInvoices[key]!;
        sortedMonthlyTotals[key] = monthlyTotals[key]!;
      }

      setState(() {
        if (isFirstCustomer) {
          customer1MonthlyInvoices = sortedMonthlyInvoices;
          customer1MonthlyTotals = sortedMonthlyTotals;
        } else {
          customer2MonthlyInvoices = sortedMonthlyInvoices;
          customer2MonthlyTotals = sortedMonthlyTotals;
        }
      });
    } catch (e) {
      log('Error loading $customerName invoices: $e');
    }
  }

  Future<void> _showCustomerSelectionDialog() async {
    String? customer1 = selectedCustomer1;
    String? customer2 = selectedCustomer2;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Two Customers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: customer1,
                hint: const Text('Customer 1'),
                onChanged: (value) => setState(() => customer1 = value),
                items: allCustomerNames
                    .map((name) =>
                        DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
              ),
              DropdownButton<String>(
                isExpanded: true,
                value: customer2,
                hint: const Text('Customer 2'),
                onChanged: (value) => setState(() => customer2 = value),
                items: allCustomerNames
                    .map((name) =>
                        DropdownMenuItem(value: name, child: Text(name)))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                if (customer1 != null &&
                    customer2 != null &&
                    customer1 != customer2) {
                  setState(() {
                    selectedCustomer1 = customer1;
                    selectedCustomer2 = customer2;
                  });
                  _saveCustomerSelection();
                  _loadInvoiceData();
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyInvoicesList(Map<String, List<Invoice>> monthlyInvoices,
      Map<String, double> monthlyTotals) {
    if (monthlyInvoices.isEmpty) {
      return const Center(
        child: Text(
          'No invoices found',
          style: TextStyle(fontSize: 16, color: CustomColors.textSecondary),
        ),
      );
    }

    List<Widget> widgets = [];

    for (String month in monthlyInvoices.keys) {
      List<Invoice> invoices = monthlyInvoices[month]!;
      double total = monthlyTotals[month]!;

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(top: 16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                month.toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CustomColors.textPrimary),
              ),
              Text(
                '₹${Global.formatAmount(total)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CustomColors.textPrimary),
              ),
            ],
          ),
        ),
      );

      for (Invoice invoice in invoices) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              leading: CircleAvatar(
                backgroundColor: CustomColors.textPrimary,
                radius: 24,
                child: Text(
                  invoice.categoryName.isNotEmpty
                      ? invoice.categoryName[0].toUpperCase()
                      : invoice.customerName[0].toUpperCase(),
                  style: TextStyle(
                      color: CustomColors.background,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              title: Text(
                invoice.categoryName,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              ),
              subtitle: Text(
                invoice.date,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              trailing: Text(
                '₹${Global.formatAmount(invoice.amount)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: CustomColors.error1),
              ),
            ),
          ),
        );
      }
    }

    return ListView(children: widgets);
  }

  Widget _buildCustomerTab(
      Map<String, List<Invoice>> invoices, Map<String, double> totals) {
    return RefreshIndicator(
      color: CustomColors.textPrimary,
      onRefresh: _loadInvoiceData,
      child: _buildMonthlyInvoicesList(invoices, totals),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Data Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No customer invoices available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(AppStrings.scpl),
        actions: [
          if (hasData)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _showCustomerSelectionDialog,
            ),
        ],
        bottom: hasData
            ? TabBar(
                controller: _tabController,
                labelColor: CustomColors.textPrimary,
                unselectedLabelColor: CustomColors.textSecondary,
                indicatorColor: CustomColors.textPrimary,
                tabs: [
                  Tab(text: selectedCustomer1 ?? 'Customer 1'),
                  Tab(text: selectedCustomer2 ?? 'Customer 2'),
                ],
              )
            : null,
      ),
      body: SafeArea(
        child: isLoading
            ? Utility.circleloading()
            : !hasData
                ? _buildNoDataWidget()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCustomerTab(
                          customer1MonthlyInvoices, customer1MonthlyTotals),
                      _buildCustomerTab(
                          customer2MonthlyInvoices, customer2MonthlyTotals),
                    ],
                  ),
      ),
    );
  }
}
