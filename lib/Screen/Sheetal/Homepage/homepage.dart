import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank_list.dart';
import 'package:sheetal/common/app_images.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/white&black_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';
import '../category/category_list.dart';
import '../customer/sheetalcustomer_list.dart';
import '../Invoices/invoice_list.dart';
import '../collection/collection_list.dart';
import '../expense/expense_list.dart';
import '../purchase/purchase_list.dart'; // Add this import

class SheetalScreen extends StatefulWidget {
  final bool isInTabView;

  const SheetalScreen({super.key, this.isInTabView = false});

  @override
  State<SheetalScreen> createState() => _SheetalScreenState();
}

class _SheetalScreenState extends State<SheetalScreen> {
  int categoryCount = 0;
  int customerCount = 0;
  int invoiceCount = 0;
  int collectionCount = 0;
  int expenseCount = 0;
  int bankCount = 0;
  int purchaseCount = 0;
  bool isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadSheetalData();
  }

  Future<void> _loadSheetalData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load categories count
      _firebaseService.getCategories().listen((categories) {
        setState(() {
          categoryCount = categories.length;
        });
      });

      // Load customers count
      _firebaseService.getSheetalCustomers().listen((customers) {
        setState(() {
          customerCount = customers.length;
        });
      });

      // Load invoices count
      _firebaseService.getInvoices().listen((invoices) {
        setState(() {
          invoiceCount = invoices.length;
        });
      });

      // Load collections count
      _firebaseService.getCollections().listen((collections) {
        setState(() {
          collectionCount = collections.length;
        });
      });

      // Load expenses count
      _firebaseService.getSheetaLExpenses().listen((expenses) {
        setState(() {
          expenseCount = expenses.length;
        });
      });

      _firebaseService.getBanks().listen((banks) {
        setState(() {
          bankCount = banks.length;
        });
      });

      // Load purchases count
      _firebaseService.getPurchases().listen((purchases) {
        setState(() {
          purchaseCount = purchases.length;
        });
      });
    } catch (e) {
      log('Error loading Sheetal data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(AppStrings.sheetal, style: AppTextStyles.headline1),
        showLeadingIcon: false,
      ),
      body: SafeArea(
        child: isLoading
            ? Utility.circleloading()
            : RefreshIndicator(
          onRefresh: _loadSheetalData,
          color: CustomColors.textPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryListScreen(),
                              ),
                            ).then((_) => _loadSheetalData());
                          },
                          child: buildCard(
                            value: categoryCount.toString(),
                            subtitle: AppStrings.category,
                            icon: Icons.category_rounded,
                            isBlackCard: true,
                            hideCurrencySymbol: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CustomerList(),
                              ),
                            ).then((_) => _loadSheetalData());
                          },
                          child: buildCard(
                            value: customerCount.toString(),
                            subtitle: AppStrings.customer,
                            icon: Icons.person,
                            hideCurrencySymbol: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Invoices and Collection Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InvoiceListScreen(),
                              ),
                            ).then((_) => _loadSheetalData());
                          },
                          child: buildCard(
                            value: invoiceCount.toString(),
                            subtitle: AppStrings.invoices,
                            icon: Icons.inventory,
                            hideCurrencySymbol: true,
                            isBlackCard: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CollectionListScreen(),
                              ),
                            ).then((_) => _loadSheetalData());
                          },
                          child: buildCard(
                            value: collectionCount.toString(),
                            subtitle: AppStrings.collection,
                            imagePath: AppImages.collection,
                            hideCurrencySymbol: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Expense and Purchase Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ExpenseListScreen(),
                              ),
                            ).then((_) => _loadSheetalData());
                          },
                          child: buildCard(
                            value: expenseCount.toString(),
                            subtitle: AppStrings.expense,
                            imagePath: AppImages.expense,
                            isBlackCard: true,
                            hideCurrencySymbol: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PurchaseListScreen(),
                              ),
                            ).then((_) => _loadSheetalData());
                          },
                          child: buildCard(
                            value: purchaseCount.toString(),
                            subtitle: 'Purchases',
                            icon: Icons.shopping_cart,
                            hideCurrencySymbol: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BankListScreen(),
                              ),
                            ).then((_) => _loadSheetalData());
                          },
                          child: buildCard(
                            value: bankCount.toString(),
                            subtitle: "Bank Collection",
                            icon: Icons.money,
                            hideCurrencySymbol: true,
                            isBlackCard: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(child: Container(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}