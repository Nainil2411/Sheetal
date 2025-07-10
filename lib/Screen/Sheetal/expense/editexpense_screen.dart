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


class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  late String _selectedPaymentMode;
  String? _paymentModeError;
  final bool _validateForm = false;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController =
        TextEditingController(text: widget.expense.amount.toString());
    _dateController = TextEditingController(text: widget.expense.expenseDate);
    _selectedPaymentMode = widget.expense.paymentMode;
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

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedExpense = Expense(
        id: widget.expense.id,
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        paymentMode: _selectedPaymentMode,
        expenseDate: _dateController.text,
        createdAt: widget.expense.createdAt,
      );

      final success =
      await _firebaseService.updateSheetaLExpense(updatedExpense);

      if (success) {
        if (mounted) {
          Navigator.pop(context, updatedExpense);
        }
      }
    } catch (e) {
      log('Error updating expense: $e');
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
        title: const Text(AppStrings.editexpense),
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    label: AppStrings.updateexpense,
                    borderRadius: 12,
                    isLoading: _isLoading,
                    onPressed: _updateExpense,
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