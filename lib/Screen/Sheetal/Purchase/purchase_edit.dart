import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase.dart';
import 'package:sheetal/Screen/Sheetal/category/category.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/common/dropdown.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class EditPurchaseScreen extends StatefulWidget {
  final Purchase purchase;

  const EditPurchaseScreen({super.key, required this.purchase});

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _graNumberController;
  bool _isLoading = false;
  List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.purchase.amount.toString());
    _dateController = TextEditingController(text: widget.purchase.date);
    _graNumberController = TextEditingController(text: widget.purchase.graNumber ?? '');
    _loadCategories();
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
                  (cat) => cat.id == widget.purchase.categoryId,
              orElse: () => categories.first,
            );
          } else {
            _selectedCategory = null;
          }
          _isLoading = false;
        });

        subscription?.cancel();
      });
    } catch (e) {
      log('Error loading categories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Parse existing date for initial date picker value
    DateTime initialDate = DateTime.now();
    try {
      initialDate = DateFormat('dd/MM/yyyy').parse(widget.purchase.date);
    } catch (e) {
      log('Error parsing date: $e');
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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

  Future<void> _updatePurchase() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updatedPurchase = Purchase(
        id: widget.purchase.id,
        categoryId: _selectedCategory!.id!,
        categoryName: _selectedCategory!.name,
        amount: double.parse(_amountController.text.trim()),
        createdAt: widget.purchase.createdAt,
        date: _dateController.text,
        graNumber: _graNumberController.text.trim().isEmpty
            ? null
            : _graNumberController.text.trim(),
      );

      final success = await _firebaseService.updatePurchase(updatedPurchase);

      if (success && mounted) {
        Navigator.pop(context, updatedPurchase);
      }
    } catch (e) {
      log('Error updating purchase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: const Text('Edit Purchase')),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date first
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
                const SizedBox(height: 16),
                // Category second
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
                // GRA Number third
                CustomTextFormField(
                  controller: _graNumberController,
                  hintText: 'Enter GRA number',
                  keyboardType: TextInputType.number,
                  showTitle: true,
                  title: 'GRA Number',
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final numeric = RegExp(r'^\d{1,}$');
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
                        return 'Amount must be greater than zero';
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
                    label: AppStrings.update,
                    onPressed: _updatePurchase,
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