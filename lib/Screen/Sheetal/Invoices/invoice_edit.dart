import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/Screen/Sheetal/customer/customer_module.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/dropdown.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class EditInvoiceScreen extends StatefulWidget {
  final Invoice invoice;

  const EditInvoiceScreen({super.key, required this.invoice});

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  bool _isLoading = false;
  List<Category> _categories = [];
  Category? _selectedCategory;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    _amountController =
        TextEditingController(text: widget.invoice.amount.toString());
    _dateController = TextEditingController(text: widget.invoice.date);
    _loadCategories();
    _loadCustomers();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      StreamSubscription? subscription;
      final stream = _firebaseService.getCategories();
      subscription = stream.listen((categories) {
        setState(() {
          _categories = categories;

          if (categories.isNotEmpty) {
            _selectedCategory = categories.firstWhere(
                  (cat) => cat.id == widget.invoice.categoryId,
              orElse: () => categories.first,
            );
          } else {
            _selectedCategory = null;
          }
        });

        subscription?.cancel();

        if (_customers.isNotEmpty) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      log('Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      StreamSubscription? subscription;
      final stream = _firebaseService.getSheetalCustomers();
      subscription = stream.listen((customers) {
        setState(() {
          _customers = customers;

          if (customers.isNotEmpty) {
            _selectedCustomer = customers.firstWhere(
                  (cus) => cus.name == widget.invoice.customerName,
              orElse: () => customers.first,
            );
          } else {
            _selectedCustomer = null;
          }
        });

        subscription?.cancel();

        if (_categories.isNotEmpty) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      log('Error loading customers: $e');
      setState(() => _isLoading = false);
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

  Future<void> _updateInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updatedInvoice = Invoice(
        id: widget.invoice.id,
        customerName: _selectedCustomer!.name,
        categoryId: _selectedCategory!.id!,
        categoryName: _selectedCategory!.name,
        amount: double.parse(_amountController.text.trim()),
        createdAt: widget.invoice.createdAt,
        date: _dateController.text,
      );

      final success = await _firebaseService.updateInvoice(updatedInvoice);

      if (success && mounted) {
        Navigator.pop(context, updatedInvoice);
      }
    } catch (e) {
      log('Error updating invoice: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: const Text(AppStrings.editinvoice)),
      body: _isLoading
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
                getSearchText: (customer) => customer.name,
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
                  });
                },
                validator: (value) =>
                value == null ? AppStrings.selectcustomer : null,
                selectedItemBuilder: (customer) =>
                    Text(customer?.name ?? AppStrings.selectcustomer),
              ),
              const SizedBox(height: 16),
              CustomDropdown<Category>(
                showTitle: true,
                title: AppStrings.category,
                hint: AppStrings.selectCategory,
                value: _selectedCategory,
                getSearchText: (category) => category.name,
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
                  });
                },
                validator: (value) =>
                value == null ? AppStrings.selectCategory : null,
                selectedItemBuilder: (category) =>
                    Text(category?.name ?? AppStrings.selectCategory),
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
                      return AppStrings.amountgreaterzero;
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
                  label: AppStrings.update,
                  onPressed: _updateInvoice,
                  borderRadius: 12,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}