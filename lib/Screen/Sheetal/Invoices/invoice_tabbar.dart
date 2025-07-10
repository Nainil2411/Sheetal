import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice_detail.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/month_picker.dart';

import 'customer_summary.dart';

class InvoiceTabsWidget extends StatefulWidget {
  final List<Invoice> allInvoices;
  final List<Invoice> filteredInvoices;
  final bool isLoading;
  final TextEditingController searchController;
  final String searchText;
  final DateTimeRange? selectedDateRange;
  final bool isSelectionMode;
  final Set<String> selectedInvoiceIds;
  final Function(String) onSearch;
  final Function() onShowDateRangePicker;
  final Function() onClearDateFilter;
  final Function(Invoice) onToggleSelection;
  final Function(Invoice) onEnterSelectionMode;
  final Function() onExitSelectionMode;
  final Function() onDeleteSelectedInvoices;
  final Function() onLoadInvoices;
  final Function(BuildContext) onImportInvoices;

  const InvoiceTabsWidget({
    super.key,
    required this.allInvoices,
    required this.filteredInvoices,
    required this.isLoading,
    required this.searchController,
    required this.searchText,
    required this.selectedDateRange,
    required this.isSelectionMode,
    required this.selectedInvoiceIds,
    required this.onSearch,
    required this.onShowDateRangePicker,
    required this.onClearDateFilter,
    required this.onToggleSelection,
    required this.onEnterSelectionMode,
    required this.onExitSelectionMode,
    required this.onDeleteSelectedInvoices,
    required this.onLoadInvoices,
    required this.onImportInvoices,
  });

  @override
  State<InvoiceTabsWidget> createState() => _InvoiceTabsWidgetState();
}

class _InvoiceTabsWidgetState extends State<InvoiceTabsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  List<CustomerSummary> _topCustomers = [];
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateTopCustomers();
  }

  @override
  void didUpdateWidget(InvoiceTabsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allInvoices != widget.allInvoices) {
      _calculateTopCustomers();
    }
  }

  void _calculateTopCustomers() {
    if (widget.allInvoices.isEmpty) {
      setState(() {
        _topCustomers = [];
      });
      return;
    }

    final Map<String, CustomerSummary> customerTotals = {};
    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final invoice in widget.allInvoices) {
      try {
        final invoiceDate = dateFormat.parse(invoice.date);

        // Check if invoice belongs to selected month
        if (invoiceDate.year == _selectedMonth.year &&
            invoiceDate.month == _selectedMonth.month) {
          final customerName = invoice.customerName;
          final key = customerName;

          if (customerTotals.containsKey(key)) {
            final existing = customerTotals[key]!;
            customerTotals[key] = CustomerSummary(
              customerName: customerName,
              totalAmount: existing.totalAmount + invoice.amount,
              invoiceCount: existing.invoiceCount + 1,
              month: DateFormat('MMMM').format(_selectedMonth),
              year: _selectedMonth.year,
            );
          } else {
            customerTotals[key] = CustomerSummary(
              customerName: customerName,
              totalAmount: invoice.amount,
              invoiceCount: 1,
              month: DateFormat('MMMM').format(_selectedMonth),
              year: _selectedMonth.year,
            );
          }
        }
      } catch (e) {
        // Skip invalid date entries
        continue;
      }
    }

    // Sort by total amount and take top 10
    final sortedCustomers = customerTotals.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    setState(() {
      _topCustomers = sortedCustomers.take(10).toList();
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _selectedMonth = newMonth;
    });
    _calculateTopCustomers();
  }

  double _calculateTotalAmount() {
    return widget.filteredInvoices
        .fold(0.0, (sum, invoice) => sum + invoice.amount);
  }

  // NEW: Select all filtered invoices
  void _selectAllInvoices() {
    // Create a temporary set with all filtered invoice IDs
    final Set<String> allFilteredIds = {};
    for (final invoice in widget.filteredInvoices) {
      if (invoice.id != null) {
        allFilteredIds.add(invoice.id!);
      }
    }

    // Call the parent's toggle function for each invoice
    for (final invoice in widget.filteredInvoices) {
      if (invoice.id != null &&
          !widget.selectedInvoiceIds.contains(invoice.id!)) {
        widget.onToggleSelection(invoice);
      }
    }
  }

  // NEW: Deselect all invoices
  void _deselectAllInvoices() {
    // Call the parent's toggle function for each selected invoice to deselect
    final List<Invoice> invoicesToDeselect = widget.filteredInvoices
        .where((invoice) => widget.selectedInvoiceIds.contains(invoice.id))
        .toList();

    for (final invoice in invoicesToDeselect) {
      widget.onToggleSelection(invoice);
    }
  }

  String _formatDate(DateTime date) {
    final dateFormat = DateFormat("dd/MM/yyyy");
    return dateFormat.format(date);
  }

  Widget _buildAllInvoicesTab() {
    Widget? dateFilterWidget = widget.selectedDateRange != null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Filtered: ${_formatDate(widget.selectedDateRange!.start)} - ${_formatDate(widget.selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClearDateFilter,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          )
        : null;

    return Column(
      children: [
        if (dateFilterWidget != null) dateFilterWidget,
        _buildTotalAmountWidget(), // Add this line
        Expanded(
          child: GenericListView<Invoice>(
            items: widget.filteredInvoices,
            isLoading: widget.isLoading,
            emptyMessage: AppStrings.noinvoicesfound,
            searchController: widget.searchController,
            onSearch: widget.onSearch,
            searchText: widget.searchText,
            getTitle: (invoice) => invoice.customerName,
            getSubtitle: (invoice) => invoice.date,
            getAmount: (invoice) => '₹${Global.formatAmount(invoice.amount)}',
            getAmountColor: (invoice) => CustomColors.error,
            getInitials: (invoice) => invoice.customerName.isNotEmpty
                ? invoice.customerName
                    .substring(0, min(2, invoice.customerName.length))
                    .toUpperCase()
                : '',
            onItemTap: (invoice) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceDetailScreen(invoice: invoice),
                ),
              );
              if (result == true) {
                widget.onLoadInvoices();
              }
            },
            onItemLongPress: (invoice) => widget.onEnterSelectionMode(invoice),
            isSelectionMode: widget.isSelectionMode,
            selectedIds: widget.selectedInvoiceIds,
            getId: (invoice) => invoice.id!,
            onSelectionToggle: (invoice) => widget.onToggleSelection(invoice),
            getDateString: (invoice) => invoice.date,
            enableSorting: true,
            sortAscending: _sortAscending,
            onSortChanged: (ascending) {
              setState(() {
                _sortAscending = ascending;
              });
            },
            onSelectAll: () => _selectAllInvoices(),
            onDeselectAll: () => _deselectAllInvoices(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopCustomersTab() {
    return Column(
      children: [
        // Month picker
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MonthPickerWidget(
                selectedDate: _selectedMonth,
                onMonthChanged: _onMonthChanged,
              ),
            ],
          ),
        ),
        // Top customers list
        Expanded(
          child: GenericListView<CustomerSummary>(
            items: _topCustomers,
            isLoading: widget.isLoading,
            emptyMessage:
                'No customers found for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
            searchController: TextEditingController(),
            // Dummy controller since search is disabled
            onSearch: (_) {},
            // Empty function since search is disabled
            searchText: '',
            filterWidget: null,
            showSearch: false,
            // Disable search for top customers
            getTitle: (customer) => customer.customerName,
            getSubtitle: (customer) =>
                '${customer.invoiceCount} invoice${customer.invoiceCount > 1 ? 's' : ''}',
            getAmount: (customer) =>
                '₹${Global.formatAmount(customer.totalAmount)}',
            getAmountColor: (customer) => CustomColors.green1,
            getInitials: (customer) => customer.customerName.isNotEmpty
                ? customer.customerName
                    .substring(0, min(2, customer.customerName.length))
                    .toUpperCase()
                : '',
            onItemTap: (customer) {
              // Optional: Navigate to customer detail or filter invoices by customer
            },
            onItemLongPress: null,
            // No long press for top customers
            isSelectionMode: false,
            selectedIds: const <String>{},
            getId: (customer) => customer.id,
            onSelectionToggle: null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Invoices'),
            Tab(text: 'Top 10 Customers'),
          ],
          labelColor: CustomColors.textPrimary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: CustomColors.textPrimary,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllInvoicesTab(),
              _buildTopCustomersTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAmountWidget() {
    if (widget.filteredInvoices.isEmpty || widget.selectedDateRange == null) {
      return const SizedBox.shrink();
    }

    final totalAmount = _calculateTotalAmount();
    final itemCount = widget.filteredInvoices.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CustomColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CustomColors.error.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtered Invoices',
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
                  color: CustomColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
