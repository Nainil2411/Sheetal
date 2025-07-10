import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/expense/expense.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/common/dropdown.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  String? _selectedPaymentMode;
  String? _paymentModeError;
  bool _validateForm = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = AppDateFormat.format(picked);
      });
    }
  }

  Future<void> _saveExpense() async {
    setState(() {
      _validateForm = true;
      _paymentModeError = null;
    });
    if (!_formKey.currentState!.validate() || _paymentModeError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final expense = Expense(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        paymentMode: _selectedPaymentMode!,
        expenseDate: _dateController.text,
      );

      final expenseId = await _firebaseService.addSheetaLExpense(expense);

      if (expenseId != null) {
        if (mounted) {
          Navigator.pop(context, expense..id = expenseId);
        }
      }
    } catch (e) {
      log('Error saving expense: $e');
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
        title: const Text(AppStrings.addexpense),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextFormField(
                  controller: _titleController,
                  showTitle: true,
                  title: AppStrings.expensename,
                  hintText: AppStrings.expensenamerequire,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppStrings.expensenamerequire;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _amountController,
                  showTitle: true,
                  title: AppStrings.amount,
                  hintText: AppStrings.amountrequire,
                  keyboardType: TextInputType.number,
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
                      return AppStrings.invalidnumber;
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
                  readOnly: true,
                  onTap: () {
                    _selectDate(context);
                  },
                  suffixIcon: const Icon(Icons.calendar_today),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomDropdown<String>(
                  showSearchBar: false,
                  title: AppStrings.paymentmethod,
                  showTitle: true,
                  value: _selectedPaymentMode,
                  items: ['Cash', 'UPI', 'Card', 'Bank Transfer', 'Cheque', 'Others']
                      .map((String mode) {
                    return DropdownMenuItem<String>(
                      value: mode,
                      child: Text(mode, style: AppTextStyles.bodyMedium),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMode = newValue!;
                      _paymentModeError = null;
                    });
                  },
                  validator: (value) =>
                  _validateForm && (value == null || value.isEmpty)
                      ? AppStrings.paymentmethodrequire
                      : null,
                  hint: AppStrings.selectPaymentMethod,
                  errorText: _paymentModeError,
                ),
                if (_paymentModeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _paymentModeError!,
                      style: AppTextStyles.errorText,
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    label: AppStrings.save,
                    borderRadius: 12,
                    isLoading: _isLoading,
                    onPressed: _saveExpense,
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