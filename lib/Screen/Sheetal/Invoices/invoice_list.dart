import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice_add.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice_tabbar.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_import.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/export_utility.dart';
import 'package:sheetal/common/range_date_picker.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String _searchText = '';
  List<Invoice> _allInvoices = [];
  List<Invoice> _filteredInvoices = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  bool _isSelectionMode = false;
  final Set<String> _selectedInvoiceIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadInvoices();

    _searchController.addListener(() {
      _filterInvoices(_searchController.text);
    });
  }

  void _loadInvoices() {
    _firebaseService.getInvoices().listen((invoices) {
      if (mounted) {
        setState(() {
          _allInvoices = invoices;
          _filterInvoices(_searchText);
          _isLoading = false;
        });
      }
    });
  }

  void _toggleSelection(Invoice invoice) {
    setState(() {
      if (_selectedInvoiceIds.contains(invoice.id)) {
        _selectedInvoiceIds.remove(invoice.id);
        if (_selectedInvoiceIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedInvoiceIds.add(invoice.id!);
      }
    });
  }

  Future<void> _exportInvoicesToExcel(BuildContext context) async {
    String? dateRangeText;
    if (_selectedDateRange != null) {
      dateRangeText = '${DateFormat("dd/MM/yyyy").format(_selectedDateRange!.start)} - ${DateFormat("dd/MM/yyyy").format(_selectedDateRange!.end)}';
    }

    await ExportUtility.exportToExcel<Invoice>(
      context: context,
      data: _filteredInvoices,
      config: ExportConfigs.invoiceConfig,
      dateRangeText: dateRangeText,
    );
  }


  void _enterSelectionMode(Invoice invoice) {
    setState(() {
      _isSelectionMode = true;
      _selectedInvoiceIds.add(invoice.id!);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedInvoiceIds.clear();
    });
  }

  Future<void> _deleteSelectedInvoices() async {
    if (_selectedInvoiceIds.isEmpty) return;

    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () {
        try {
          _firebaseService
              .deleteMultipleInvoices(_selectedInvoiceIds.toList())
              .then((success) {
            if (success) {
              _exitSelectionMode();
            }
          });
        } catch (e) {
          // Handle error silently
        }
      },
    );
  }

  void _filterInvoices(String searchText) {
    setState(() {
      _searchText = searchText.toLowerCase();
      _filteredInvoices = _allInvoices.where((invoice) {
        final matchesSearch =
            invoice.customerName.toLowerCase().contains(_searchText) ||
                invoice.categoryName.toLowerCase().contains(_searchText);
        final matchesDateRange = _isInDateRange(invoice);
        return matchesSearch && matchesDateRange;
      }).toList();
    });
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
        _filterInvoices(_searchText);
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _filterInvoices(_searchText);
    });
  }

  bool _isInDateRange(Invoice invoice) {
    if (_selectedDateRange == null) return true;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final invoiceDate = dateFormat.parse(invoice.date);

    final endDate = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
      23,
      59,
      59,
    );

    return (invoiceDate.isAfter(_selectedDateRange!.start) ||
        invoiceDate.isAtSameMomentAs(_selectedDateRange!.start)) &&
        (invoiceDate.isBefore(endDate) ||
            invoiceDate.isAtSameMomentAs(endDate));
  }

  Future<void> _importInvoicesFromFile(BuildContext context) async {
    await ImportUtility.importFromFile<Invoice>(
      context: context,
      config: ImportConfigs.invoiceConfig,
      onComplete: () {
        setState(() {});
      },
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
        title: Text(_isSelectionMode
            ? '${_selectedInvoiceIds.length} selected'
            : AppStrings.invoices),
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
            onPressed: _deleteSelectedInvoices,
          ),
        ]
            : [
          IconButton(
            icon: const Icon(Icons.filter_list,
                color: CustomColors.textPrimary),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: InvoiceTabsWidget(
          allInvoices: _allInvoices,
          filteredInvoices: _filteredInvoices,
          isLoading: _isLoading,
          searchController: _searchController,
          searchText: _searchText,
          selectedDateRange: _selectedDateRange,
          isSelectionMode: _isSelectionMode,
          selectedInvoiceIds: _selectedInvoiceIds,
          onSearch: _filterInvoices,
          onShowDateRangePicker: _showDateRangePicker,
          onClearDateFilter: _clearDateFilter,
          onToggleSelection: _toggleSelection,
          onEnterSelectionMode: _enterSelectionMode,
          onExitSelectionMode: _exitSelectionMode,
          onDeleteSelectedInvoices: _deleteSelectedInvoices,
          onLoadInvoices: _loadInvoices,
          onImportInvoices: _importInvoicesFromFile,
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
              children: [
                // Import FAB
                FloatingActionButton(
                  heroTag: 'importInvoiceFab',
                  onPressed: () => _importInvoicesFromFile(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.upload_file, color: Colors.white),
                ),
                const SizedBox(width: 10),
                // Export FAB
                FloatingActionButton(
                  heroTag: 'exportInvoiceFab',
                  onPressed: () => _exportInvoicesToExcel(context),
                  backgroundColor: CustomColors.textSecondary,
                  child: const Icon(Icons.download, color: Colors.white),
                ),
                const SizedBox(width: 200),
                // Add FAB
                CustomFAB(
                  heroTag: 'addInvoiceFab',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddInvoiceScreen(),
                      ),
                    );
                    _loadInvoices();
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