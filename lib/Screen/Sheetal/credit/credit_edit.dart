import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/discount/discount.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/utils/firebase_service.dart';

class EditCreditScreen extends StatefulWidget {
  final Discount credit;
  const EditCreditScreen({super.key, required this.credit});

  @override
  State<EditCreditScreen> createState() => _EditCreditScreenState();
}

class _EditCreditScreenState extends State<EditCreditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final FirebaseService _firebaseService = FirebaseService();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _monthController = TextEditingController(text: widget.credit.month);
    _amountController = TextEditingController(text: widget.credit.amount.toString());
    _noteController = TextEditingController(text: widget.credit.notes ?? '');
    _selectedDate = _tryParseExisting(widget.credit.month);
  }

  DateTime? _tryParseExisting(String value) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(value);
    } catch (_) {
      try {
        return DateFormat('MMMM yyyy').parse(value);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _monthController.text = AppDateFormat.format(picked);
      });
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = Discount(
        id: widget.credit.id,
        month: _monthController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: widget.credit.createdAt,
      );
      final ok = await _firebaseService.updateCredit(updated);
      if (ok && mounted) Navigator.pop(context, updated);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: const Text('Edit Credit')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextFormField(
                  title: AppStrings.date,
                  showTitle: true,
                  controller: _monthController,
                  hintText: AppStrings.selectDate,
                  showBorders: true,
                  borderColor: CustomColors.textSecondary.withOpacity(0.5),
                  readOnly: true,
                  onTap: _selectDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Please select a date' : null,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _amountController,
                  showTitle: true,
                  title: "Credit Amount*",
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
                    label: AppStrings.update,
                    isLoading: _isLoading,
                    borderRadius: 12,
                    onPressed: _update,
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


