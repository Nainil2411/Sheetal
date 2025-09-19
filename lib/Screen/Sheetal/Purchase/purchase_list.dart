import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _searchText = '';
  List<Purchase> _allPurchases = [];
  List<Purchase> _filteredPurchases = [];
  bool _isLoading = true;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
    _searchController.addListener(() {
      _filterPurchases(_searchController.text);
    });
  }

  void _loadPurchases() {
    _firebaseService.getPurchases().listen((purchases) {
      if (mounted) {
        setState(() {
          _allPurchases = _sortPurchasesByDate(purchases);
          _filterPurchases(_searchText);
          _isLoading = false;
        });
      }
    });
  }

  // Helper method to sort purchases by date (latest first)
  List<Purchase> _sortPurchasesByDate(List<Purchase> purchases) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    List<Purchase> sortedPurchases = List.from(purchases);
    sortedPurchases.sort((a, b) {
      try {
        final dateA = dateFormat.parse(a.date);
        final dateB = dateFormat.parse(b.date);
        return dateB.compareTo(dateA); // Latest first (descending order)
      } catch (e) {
        // If there's an error parsing dates, maintain original order
        return 0;
      }
    });

    return sortedPurchases;
  }

  void _filterPurchases(String searchText) {
    setState(() {
      _searchText = searchText.toLowerCase();
      List<Purchase> filtered = _allPurchases.where((purchase) =>
      purchase.categoryName.toLowerCase().contains(_searchText) ||
          purchase.date.toLowerCase().contains(_searchText) ||
          (purchase.graNumber ?? '').toLowerCase().contains(_searchText)
      ).toList();

      // Sort filtered results by date as well (latest first)
      _filteredPurchases = _sortPurchasesByDate(filtered);
    });
  }

  Future<void> _importPurchasesFromFile(BuildContext context) async {
    await ImportUtility.importFromFile<Purchase>(
      context: context,
      config: ImportConfigs.purchaseConfig,
      onComplete: () {
        setState(() {});
      },
    );
  }

  Future<void> _exportPurchasesToExcel(BuildContext context) async {
    await ExportUtility.exportToExcel<Purchase>(
      context: context,
      data: _filteredPurchases,
      config: ExportConfigs.purchaseConfig,
    );
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
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: GenericListView<Purchase>(
          items: _filteredPurchases,
          isLoading: _isLoading,
          emptyMessage: 'No purchases found',
          searchController: _searchController,
          onSearch: _filterPurchases,
          searchText: _searchText,
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
                  onPressed: () => _importPurchasesFromFile(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.upload_file, color: Colors.white),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  heroTag: 'exportPurchaseFab',
                  onPressed: () => _exportPurchasesToExcel(context),
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