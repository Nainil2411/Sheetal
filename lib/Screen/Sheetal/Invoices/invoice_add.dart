import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/Screen/Sheetal/customer/customer_module.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/common/dropdown.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({super.key});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _validateForm = false; // Add validation trigger
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  String? _customerError; // Add error text for customer dropdown
  String? _categoryError; // Add error text for category dropdown

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCustomers();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categoriesStream = _firebaseService.getCategories();
      StreamSubscription? subscription;
      subscription = categoriesStream.listen((categories) {
        setState(() {
          _categories = categories;
        });
        subscription?.cancel();
        if (_customers.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      log('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customersStream = _firebaseService.getSheetalCustomers();
      StreamSubscription? subscription;
      subscription = customersStream.listen((customers) {
        setState(() {
          _customers = customers;
        });
        subscription?.cancel();
        if (_categories.isNotEmpty) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      log('Error loading customers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = AppDateFormat.format(picked);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _saveInvoice() async {
    // Set validation trigger to true
    setState(() {
      _validateForm = true;
    });

    if (!_formKey.currentState!.validate()) return;

    // Check if customer is selected
    if (_selectedCustomer == null) {
      setState(() {
        _customerError = AppStrings.selectcustomer;
      });
      return;
    }

    // Check if category is selected
    if (_selectedCategory == null) {
      setState(() {
        _categoryError = AppStrings.selectCategory;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final invoice = Invoice(
        customerName: _selectedCustomer!.name,
        categoryId: _selectedCategory!.id!,
        categoryName: _selectedCategory!.name,
        amount: double.parse(_amountController.text.trim()),
        createdAt: Timestamp.now(),
        date: _dateController.text,
      );
      final invoiceId = await _firebaseService.addInvoice(invoice);
      if (invoiceId != null) {
        if (mounted) {
          Navigator.pop(context, invoice..id = invoiceId);
        }
      }
    } catch (e) {
      log('Error saving invoice: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.addinvoice),
      ),
      body: SingleChildScrollView(
        child: _isLoading
            ? Utility.circleloading()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomDropdown<Customer>(
                  showTitle: true,
                  title: AppStrings.customer,
                  hint: AppStrings.selectcustomer,
                  value: _selectedCustomer,
                  items: _customers.isEmpty
                      ? [
                    DropdownMenuItem<Customer>(
                      value: null,
                      child: Text(AppStrings.nocustomer),
                    ),
                  ]
                      : _customers.map((customer) {
                    return DropdownMenuItem<Customer>(
                      value: customer,
                      child: Text(customer.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCustomer = newValue;
                      _customerError = null; // Clear error when selection is made
                    });
                  },
                  validator: (value) =>
                  _validateForm && value == null ? AppStrings.selectcustomer : null,
                  selectedItemBuilder: (customer) =>
                      Text(customer?.name ?? AppStrings.selectcustomer),
                  errorText: _customerError,
                  getSearchText: (customer) => customer.name,
                ),
                // Show error text if customer error exists
                if (_customerError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _customerError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                CustomDropdown<Category>(
                  showTitle: true,
                  title: AppStrings.category,
                  hint: AppStrings.selectCategory,
                  value: _selectedCategory,
                  items: _categories.isEmpty
                      ? [
                    DropdownMenuItem<Category>(
                      value: null,
                      child: Text(AppStrings.nocategoryfound),
                    ),
                  ]
                      : _categories.map((category) {
                    return DropdownMenuItem<Category>(
                      value: category,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                      _categoryError = null; // Clear error when selection is made
                    });
                  },
                  validator: (value) =>
                  _validateForm && value == null ? AppStrings.selectCategory : null,
                  selectedItemBuilder: (category) =>
                      Text(category?.name ?? AppStrings.selectCategory),
                  errorText: _categoryError,
                  getSearchText: (category) => category.name,
                ),
                // Show error text if category error exists
                if (_categoryError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _categoryError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _amountController,
                  hintText: AppStrings.amountrequire,
                  keyboardType: TextInputType.number,
                  showTitle: true,
                  title: AppStrings.amount,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.amountrequire;
                    }
                    try {
                      final amount = double.parse(value);
                      if (amount <= 0) {
                        return AppStrings.amountrequire;
                      }
                    } catch (e) {
                      return AppStrings.amountrequire;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  title: AppStrings.date,
                  showTitle: true,
                  controller: _dateController,
                  hintText: AppStrings.selectDate,
                  showBorders: true,
                  errorText: '',
                  onChanged: (value) {},
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                  readOnly: true,
                  onTap: () {
                    _selectDate(context);
                  },
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    label: AppStrings.save,
                    onPressed: _saveInvoice,
                    borderRadius: 12,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}