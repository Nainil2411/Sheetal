import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/customer/add_sheetalcustomer.dart';
import 'package:sheetal/Screen/Sheetal/customer/customer_module.dart';
import 'package:sheetal/Screen/Sheetal/customer/sheetalcustomer_detail.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_import.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/custom_listview.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerList> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  Stream<List<Customer>>? _customersStream;
  bool _isSelectionMode = false;
  final Set<String> _selectedCustomerIds = <String>{};

  @override
  void initState() {
    super.initState();
    _customersStream = _firebaseService.getSheetalCustomers();
  }

  void _toggleSelection(Customer customer) {
    setState(() {
      if (_selectedCustomerIds.contains(customer.id)) {
        _selectedCustomerIds.remove(customer.id);
        if (_selectedCustomerIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedCustomerIds.add(customer.id!);
      }
    });
  }

  void _enterSelectionMode(Customer customer) {
    setState(() {
      _isSelectionMode = true;
      _selectedCustomerIds.add(customer.id!);
    });
  }

  void _exitSelectionMode() {
    if(mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedCustomerIds.clear();
      });
    }
  }

  // NEW: Select all customers
  void _selectAllCustomers(List<Customer> customers) {
    setState(() {
      _selectedCustomerIds.clear();
      for (final customer in customers) {
        if (customer.id != null) {
          _selectedCustomerIds.add(customer.id!);
        }
      }
    });
  }

  // NEW: Deselect all customers
  void _deselectAllCustomers() {
    setState(() {
      _selectedCustomerIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedCustomers(List<Customer> allCustomers) async {
    final selectedCustomers = allCustomers
        .where((customer) => _selectedCustomerIds.contains(customer.id))
        .toList();

    if (selectedCustomers.isEmpty) return;

    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () {
        try {
          _firebaseService
              .deleteMultipleCustomersWithRelatedData(selectedCustomers)
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

  Future<void> _importCustomersFromFile(BuildContext context) async {
    await ImportUtility.importFromFile<Customer>(
      context: context,
      config: ImportConfigs.customerConfig,
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
    return StreamBuilder<List<Customer>>(
      stream: _customersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: CustomAppBar(title: Text(AppStrings.customers)),
            body: Utility.circleloading(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: CustomAppBar(title: Text(AppStrings.customers)),
            body: Center(
                child:
                Text(AppStrings.genericError + snapshot.error.toString())),
          );
        }

        final allCustomers = snapshot.data ?? [];
        final searchText = _searchController.text.toLowerCase();
        final filteredCustomers = allCustomers.where((customer) {
          return customer.name.toLowerCase().contains(searchText) ||
              customer.phone.toLowerCase().contains(searchText);
        }).toList();

        return Scaffold(
          appBar: CustomAppBar(
            title: Text(_isSelectionMode
                ? '${_selectedCustomerIds.length} selected'
                : AppStrings.customers),
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
                onPressed: () async {
                  await _deleteSelectedCustomers(allCustomers);
                },
              ),
            ]
                : null,
          ),
          body: Padding(
            padding: EdgeInsets.only(bottom: 80),
            child: GenericListView<Customer>(
              items: filteredCustomers,
              isLoading: false,
              emptyMessage: AppStrings.nouserfound,
              searchController: _searchController,
              onSearch: (_) => setState(() {}),
              searchText: searchText,
              getTitle: (customer) => customer.name,
              getSubtitle: (customer) => '+91 ${customer.phone}',
              getInitials: (customer) => customer.name.isNotEmpty
                  ? customer.name
                  .substring(0, min(2, customer.name.length))
                  .toUpperCase()
                  : '',
              onItemTap: (customer) async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CustomerDetailScreen(customer: customer),
                  ),
                );
                if (result == true) {}
              },
              onItemLongPress: (customer) => _enterSelectionMode(customer),
              isSelectionMode: _isSelectionMode,
              selectedIds: _selectedCustomerIds,
              getId: (customer) => customer.id!,
              onSelectionToggle: (customer) => _toggleSelection(customer),
              // NEW: Add select all functionality
              onSelectAll: () => _selectAllCustomers(filteredCustomers),
              onDeselectAll: () => _deselectAllCustomers(),
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
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FloatingActionButton(
                      heroTag: 'importFab',
                      onPressed: () => _importCustomersFromFile(context),
                      child: const Icon(Icons.upload_file),
                    ),
                    const SizedBox(height: 16),
                    CustomFAB(
                      heroTag: 'addFab',
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const AddCustomerScreen(),
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
      },
    );
  }
}