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

class EditSchemeScreen extends StatefulWidget {
  final Discount scheme;
  const EditSchemeScreen({super.key, required this.scheme});

  @override
  State<EditSchemeScreen> createState() => _EditSchemeScreenState();
}

class _EditSchemeScreenState extends State<EditSchemeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _monthController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final FirebaseService _firebaseService = FirebaseService();

  DateTime? _selectedMonth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _monthController = TextEditingController(text: widget.scheme.month);
    _amountController = TextEditingController(text: widget.scheme.amount.toString());
    _noteController = TextEditingController(text: widget.scheme.notes ?? '');
    _selectedMonth = _tryParseMonth(widget.scheme.month);
  }

  DateTime? _tryParseMonth(String value) {
    try {
      return DateFormat('MMMM yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearPicker(context, initialDate: _selectedMonth ?? DateTime.now());
    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
        _monthController.text = DateFormat('MMMM yyyy').format(_selectedMonth!);
      });
    }
  }

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = Discount(
        id: widget.scheme.id,
        month: _monthController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        createdAt: widget.scheme.createdAt,
      );
      final ok = await _firebaseService.updateScheme(updated);
      if (ok && mounted) Navigator.pop(context, updated);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: const Text('Edit Scheme')),
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
                  title: "Scheme Amount*",
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


