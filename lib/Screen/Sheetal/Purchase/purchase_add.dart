import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/dropdown.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _graNumberController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _validateForm = false; // Add this validation trigger
  List<Category> _categories = [];
  Category? _selectedCategory;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
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
          _isLoading = false;
        });
        subscription?.cancel();
      });
    } catch (e) {
      log('Error loading categories: $e');
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
    _graNumberController.dispose();
    super.dispose();
  }

  Future<void> _savePurchase() async {
    // Set validation trigger to true
    setState(() {
      _validateForm = true;
    });

    if (!_formKey.currentState!.validate()) return;

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
      final purchase = Purchase(
        date: _dateController.text,
        categoryId: _selectedCategory!.id!,
        categoryName: _selectedCategory!.name,
        amount: double.parse(_amountController.text.trim()),
        graNumber: _graNumberController.text.trim().isEmpty
            ? null
            : _graNumberController.text.trim(),
        createdAt: DateTime.now(),
      );

      final purchaseId = await _firebaseService.addPurchase(purchase);

      if (purchaseId != null) {
        if (mounted) {
          Navigator.pop(context, purchase..id = purchaseId);
        }
      }
    } catch (e) {
      log("Error saving purchase: $e");
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
        title: const Text('Add Purchase'),
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
                // Date
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
                const SizedBox(height: 16),
                // Category
                CustomDropdown<Category>(
                  showTitle: true,
                  title: AppStrings.category,
                  hint: AppStrings.selectCategory,
                  getSearchText: (category) => category.name,
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
                  errorText: _categoryError, // Add error text
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
                // GRA Number
                CustomTextFormField(
                  controller: _graNumberController,
                  hintText: 'Enter GRA number',
                  keyboardType: TextInputType.number,
                  showTitle: true,
                  title: 'GRA Number',
                  validator: (value) {
                    // Only validate when _validateForm is true (after save button is pressed)
                    if (_validateForm) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter GRA number';
                      }
                      // Check if it's numeric
                      final numeric = RegExp(r'^\d+$');
                      if (!numeric.hasMatch(value.trim())) {
                        return 'Enter a valid numeric GRA number';
                      }
                    }
                    return null;
                  },
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    label: AppStrings.save,
                    onPressed: _savePurchase,
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