import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/common/month_picker.dart';
import 'package:sheetal/utils/firebase_service.dart';

class AddDiscountScreen extends StatefulWidget {
  const AddDiscountScreen({super.key});

  @override
  State<AddDiscountScreen> createState() => _AddDiscountScreenState();
}

class _AddDiscountScreenState extends State<AddDiscountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _monthController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  DateTime? _selectedMonth;
  bool _isLoading = false;

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showMonthYearPicker(
      context,
      initialDate: _selectedMonth ?? now,
      latestAllowed: DateTime(now.year, now.month),
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _monthController.text = DateFormat('MMMM yyyy').format(_selectedMonth!);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final discount = Discount(
        month: _monthController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      final id = await _firebaseService.addDiscount(discount);
      if (id != null && mounted) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: const Text('Add Discount')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextFormField(
                  title: 'Month*',
                  showTitle: true,
                  controller: _monthController,
                  hintText: 'Select Month',
                  showBorders: true,
                  borderColor: CustomColors.textSecondary.withOpacity(0.5),
                  readOnly: true,
                  onTap: _pickMonth,
                  suffixIcon: const Icon(Icons.calendar_today),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please select month' : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _amountController,
                  showTitle: true,
                  title: 'Discount Amount*',
                  hintText: AppStrings.amountrequire,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return AppStrings.amountrequire;
                    try {
                      final amount = double.parse(value);
                      if (amount <= 0) return AppStrings.amountgreaterzero;
                    } catch (_) {
                      return AppStrings.invalidnumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _noteController,
                  showTitle: true,
                  title: AppStrings.notes,
                  hintText: 'Optional notes',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    onPressed: _save,
                    isLoading: _isLoading,
                    label: AppStrings.save,
                    borderRadius: 12,
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


