import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase_add.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase_detail.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/export_utility.dart';
import 'package:sheetal/common/common_import.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  Stream<List<Purchase>>? _purchasesStream;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _purchasesStream = _firebaseService.getPurchases();
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
        title: const Text('Purchases'),
      ),
      body: StreamBuilder<List<Purchase>>(
        stream: _purchasesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Utility.circleloading();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }

          final allPurchases = snapshot.data ?? [];
          final searchText = _searchController.text.toLowerCase();
          final filteredPurchases = allPurchases.where((purchase) {
            return purchase.categoryName.toLowerCase().contains(searchText) ||
                purchase.date.toLowerCase().contains(searchText);
          }).toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: GenericListView<Purchase>(
              items: filteredPurchases,
              isLoading: false,
              emptyMessage: 'No purchases found',
              searchController: _searchController,
              onSearch: (_) => setState(() {}),
              searchText: searchText,
              getTitle: (purchase) => purchase.categoryName,
              getAmount: (purchase) => '₹${Global.formatAmount(purchase.amount)}',
              getAmountColor: (purchase) => CustomColors.error,
              getSubtitle: (purchase) => purchase.date,
              getInitials: (purchase) => purchase.categoryName.isNotEmpty
                  ? purchase.categoryName.substring(0, min(2, purchase.categoryName.length)).toUpperCase()
                  : 'P',
              getDateString: (purchase) => purchase.date,
              enableSorting: true,
              sortAscending: _sortAscending,
              onSortChanged: (ascending) {
                setState(() {
                  _sortAscending = ascending;
                });
              },
              onItemTap: (purchase) async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PurchaseDetailScreen(purchase: purchase),
                  ),
                );
                if (result == true) {
                  // Refresh handled by stream
                }
              },
            ),
          );
        },
      ),
      bottomSheet: BottomSheet(
        shape: Border.all(color: CustomColors.background),
        backgroundColor: CustomColors.background,
        onClosing: () {},
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FloatingActionButton(
                  heroTag: 'importPurchaseFab',
                  onPressed: () async {
                    await ImportUtility.importFromFile<Purchase>(
                      context: context,
                      config: ImportConfigs.purchaseConfig,
                      onComplete: () {
                        setState(() {});
                      },
                    );
                  },
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.upload_file, color: Colors.white),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  heroTag: 'exportPurchaseFab',
                  onPressed: () async {
                    final allPurchases = (await _purchasesStream?.first) ?? [];
                    final searchText = _searchController.text.toLowerCase();
                    final filtered = allPurchases.where((p) =>
                      p.categoryName.toLowerCase().contains(searchText) ||
                      p.date.toLowerCase().contains(searchText)
                    ).toList();
                    await ExportUtility.exportToExcel<Purchase>(
                      context: context,
                      data: filtered,
                      config: ExportConfigs.purchaseConfig,
                    );
                  },
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.download, color: Colors.white),
                ),
                const SizedBox(width: 200),
                CustomFAB(
                  heroTag: 'addPurchaseFab',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddPurchaseScreen(),
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
}