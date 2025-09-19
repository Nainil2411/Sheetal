import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection_add.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection_detail.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection_filter.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_import.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/export_utility.dart';
import 'package:sheetal/common/range_date_picker.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class CollectionListScreen extends StatefulWidget {
  const CollectionListScreen({super.key});

  @override
  State<CollectionListScreen> createState() => _CollectionListScreenState();
}

class _CollectionListScreenState extends State<CollectionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String _searchText = "";
  List<Collection> _allCollections = [];
  List<Collection> _filteredCollections = [];
  bool _isLoading = true;
  bool _sortAscending = false;
  DateTimeRange? _selectedDateRange;
  final progressNotifier = ValueNotifier<int>(0);

  Set<String> _selectedPaymentModes = <String>{};
  final List<String> _availablePaymentModes = [
    'Cash',
    'Cheque',
    'UPI',
    'Card',
    'Bank Transfer',
    'Other'
  ];

  bool _isSelectionMode = false;
  final Set<String> _selectedCollectionIds = <String>{};

  StreamSubscription<List<Collection>>? _collectionsSubscription;

  @override
  void initState() {
    super.initState();
    _loadCollections();

    _searchController.addListener(() {
      _filterCollections(_searchController.text);
    });
  }

  Future<void> _exportCollectionsToExcel(BuildContext context) async {
    String? dateRangeText;
    if (_selectedDateRange != null) {
      dateRangeText = '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}';
    }

    await ExportUtility.exportToExcel<Collection>(
      context: context,
      data: _filteredCollections,
      config: ExportConfigs.collectionConfig,
      dateRangeText: dateRangeText,
    );
  }

  void _loadCollections() {
    _collectionsSubscription?.cancel();
    _collectionsSubscription =
        _firebaseService.getCollections().listen((collections) {
          if (mounted) {
            setState(() {
              _allCollections = _sortCollectionsByDate(collections);
              _filterCollections(_searchText);
              _isLoading = false;
            });
          }
        });
  }

  // Helper method to sort collections by date (latest first)
  List<Collection> _sortCollectionsByDate(List<Collection> collections) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    List<Collection> sortedCollections = List.from(collections);
    sortedCollections.sort((a, b) {
      try {
        final dateA = dateFormat.parse(a.date);
        final dateB = dateFormat.parse(b.date);
        return dateB.compareTo(dateA); // Latest first (descending order)
      } catch (e) {
        // If there's an error parsing dates, maintain original order
        return 0;
      }
    });

    return sortedCollections;
  }

  void _toggleSelection(Collection collection) {
    setState(() {
      if (_selectedCollectionIds.contains(collection.id)) {
        _selectedCollectionIds.remove(collection.id);
        if (_selectedCollectionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedCollectionIds.add(collection.id!);
      }
    });
  }

  double _calculateTotalAmount() {
    return _filteredCollections.fold(0.0, (sum, collection) => sum + collection.amount);
  }

  void _enterSelectionMode(Collection collection) {
    setState(() {
      _isSelectionMode = true;
      _selectedCollectionIds.add(collection.id!);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedCollectionIds.clear();
    });
  }

  Future<void> _deleteSelectedCollections() async {
    if (_selectedCollectionIds.isEmpty) return;

    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () {
        try {
          _firebaseService
              .deleteMultipleCollections(_selectedCollectionIds.toList())
              .then((success) {
            if (success && mounted) {
              _exitSelectionMode();
            }
          });
        } catch (e) {
          // Handle error silently
        }
      },
    );
  }

  void _filterCollections(String searchText) {
    if (!mounted) return;

    setState(() {
      _searchText = searchText.toLowerCase();
      List<Collection> filtered = _allCollections.where((collection) {
        final matchesSearch =
            collection.customerName.toLowerCase().contains(_searchText) ||
                collection.paymentMode.toLowerCase().contains(_searchText);
        final matchesDateRange = _isInDateRange(collection);
        final matchesPaymentMode = _matchesPaymentModeFilter(collection);
        return matchesSearch && matchesDateRange && matchesPaymentMode;
      }).toList();

      // Sort filtered results by date as well (latest first)
      _filteredCollections = _sortCollectionsByDate(filtered);
    });
  }

  bool _matchesPaymentModeFilter(Collection collection) {
    if (_selectedPaymentModes.isEmpty) return true;

    return _selectedPaymentModes.any(
            (mode) => collection.paymentMode.toLowerCase() == mode.toLowerCase());
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

    if (result != null && mounted) {
      setState(() {
        _selectedDateRange = result;
        _filterCollections(_searchText);
      });
    }
  }

  void _showPaymentModeFilter() async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext context) {
        return PaymentModeFilterDialog(
          availablePaymentModes: _availablePaymentModes,
          selectedPaymentModes: _selectedPaymentModes,
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedPaymentModes = result;
        _filterCollections(_searchText);
      });
    }
  }

  void _clearDateFilter() {
    if (!mounted) return;

    setState(() {
      _selectedDateRange = null;
      _filterCollections(_searchText);
    });
  }

  void _clearAllFilters() {
    if (!mounted) return;

    setState(() {
      _selectedDateRange = null;
      _selectedPaymentModes.clear();
      _filterCollections(_searchText);
    });
  }

  bool _isInDateRange(Collection collection) {
    if (_selectedDateRange == null) return true;

    try {
      final dateFormat = DateFormat("dd/MM/yyyy");
      final collectionDate = dateFormat.parse(collection.date);

      final endDate = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );

      return (collectionDate.isAfter(_selectedDateRange!.start) ||
          collectionDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
          (collectionDate.isBefore(endDate) ||
              collectionDate.isAtSameMomentAs(endDate));
    } catch (e) {
      return true;
    }
  }

  String _formatDate(DateTime date) {
    final dateFormat = DateFormat("dd/MM/yyyy");
    return dateFormat.format(date);
  }

  Future<void> _importCollectionsFromFile(BuildContext context) async {
    await ImportUtility.importFromFile<Collection>(
      context: context,
      config: ImportConfigs.collectionConfig,
      onComplete: () {
        setState(() {});
      },
    );
  }

  void _selectAllCollection() {
    setState(() {
      _selectedCollectionIds.clear();
      for (final collection in _filteredCollections) {
        if (collection.id != null) {
          _selectedCollectionIds.add(collection.id!);
        }
      }
    });
  }

  // NEW: Deselect all collections
  void _deselectAllCollection() {
    setState(() {
      _selectedCollectionIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  void dispose() {
    _collectionsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChips() {
    List<Widget> chips = [];
    if (_selectedDateRange != null) {
      chips.add(
        FilterChip(
          label: Text(
            'Date: ${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
            style: const TextStyle(fontSize: 12),
          ),
          onDeleted: _clearDateFilter,
          deleteIcon: const Icon(Icons.close, size: 16),
          onSelected: (bool value) {},
        ),
      );
      chips.add(const SizedBox(width: 8));
    }

    for (String mode in _selectedPaymentModes) {
      chips.add(
        FilterChip(
          label: Text(mode, style: const TextStyle(fontSize: 12)),
          onDeleted: () {
            setState(() {
              _selectedPaymentModes.remove(mode);
              _filterCollections(_searchText);
            });
          },
          deleteIcon: const Icon(Icons.close, size: 16),
          onSelected: (bool value) {},
        ),
      );
      chips.add(const SizedBox(width: 8));
    }

    if (_selectedDateRange != null || _selectedPaymentModes.isNotEmpty) {
      chips.add(
        ActionChip(
          label: const Text('Clear All', style: TextStyle(fontSize: 12)),
          onPressed: _clearAllFilters,
          backgroundColor: Colors.red[100],
        ),
      );
    }

    return chips.isEmpty
        ? const SizedBox.shrink()
        : Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(_isSelectionMode
            ? '${_selectedCollectionIds.length} selected'
            : AppStrings.collection),
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
            onPressed: _deleteSelectedCollections,
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.date_range,
                color: CustomColors.textPrimary),
            onPressed: _showDateRangePicker,
            tooltip: 'Date Filter',
          ),
          IconButton(
            icon: const Icon(Icons.payment,
                color: CustomColors.textPrimary),
            onPressed: _showPaymentModeFilter,
            tooltip: 'Payment Mode Filter',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          children: [
            _buildFilterChips(),
            _buildTotalAmountWidget(), // Add this line
            Expanded(
              child: GenericListView<Collection>(
                // ... rest of your existing GenericListView code
                items: _filteredCollections,
                isLoading: _isLoading,
                emptyMessage: AppStrings.nocollection,
                searchController: _searchController,
                onSearch: _filterCollections,
                searchText: _searchText,
                onSelectAll: _selectAllCollection,
                onDeselectAll: _deselectAllCollection,
                getTitle: (collection) => collection.customerName,
                getAmount: (collection) =>
                '₹${Global.formatAmount(collection.amount)}',
                getAmountColor: (_) => CustomColors.green1,
                getSubtitle: (collection) => collection.date,
                getInitials: (collection) => collection.customerName.isNotEmpty
                    ? collection.customerName
                    .substring(0, min(2, collection.customerName.length))
                    .toUpperCase()
                    : '',
                onItemTap: (collection) async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CollectionDetailScreen(collection: collection),
                    ),
                  );
                  if (result == true && mounted) {
                    _loadCollections();
                  }
                },
                onItemLongPress: (collection) =>
                    _enterSelectionMode(collection),
                isSelectionMode: _isSelectionMode,
                selectedIds: _selectedCollectionIds,
                getId: (collection) => collection.id!,
                onSelectionToggle: (collection) => _toggleSelection(collection),
                getDateString: (collection) => collection.date,
                enableSorting: true,
                sortAscending: _sortAscending,
                onSortChanged: (ascending) {
                  setState(() {
                    _sortAscending = ascending;
                  });
                },
              ),
            ),
          ],
        ),
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Import FAB
                FloatingActionButton(
                  heroTag: 'importCollectionFab',
                  onPressed: () => _importCollectionsFromFile(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.upload_file, color: Colors.white),
                ),
                const SizedBox(width: 10),
                // Export FAB
                FloatingActionButton(
                  heroTag: 'exportCollectionFab',
                  onPressed: () => _exportCollectionsToExcel(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.download, color: Colors.white),
                ),
                const SizedBox(width: 200),
                // Add Collection FAB
                CustomFAB(
                  heroTag: 'addCollectionFab',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCollectionScreen(),
                      ),
                    );
                    if (mounted) {
                      _loadCollections();
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalAmountWidget() {
    if (_filteredCollections.isEmpty ||
        (_selectedDateRange == null && _selectedPaymentModes.isEmpty)) {
      return const SizedBox.shrink();
    }

    final totalAmount = _calculateTotalAmount();
    final itemCount = _filteredCollections.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CustomColors.green1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CustomColors.green1.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtered Collections',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$itemCount item${itemCount != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${Global.formatAmount(totalAmount)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: CustomColors.green1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}