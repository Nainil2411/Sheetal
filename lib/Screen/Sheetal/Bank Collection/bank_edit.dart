import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class EditBankScreen extends StatefulWidget {
  final Bank bank;
  const EditBankScreen({super.key, required this.bank});

  @override
  State<EditBankScreen> createState() => _EditBankScreenState();
}

class _EditBankScreenState extends State<EditBankScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateController;
  late TextEditingController _invoiceTotalController;
  late TextEditingController _cashController;
  late TextEditingController _onlineController;
  late TextEditingController _chequeController;
  late TextEditingController _othersController;
  late TextEditingController _totalController;
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  DateTime? _selectedDate;
  double _invoiceTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.bank.selectedDate);
    _invoiceTotalController = TextEditingController(text: widget.bank.invoiceTotal.toString());
    _cashController = TextEditingController(text: widget.bank.cash.toString());
    _onlineController = TextEditingController(text: widget.bank.online.toString());
    _chequeController = TextEditingController(text: widget.bank.cheque.toString());
    _othersController = TextEditingController(text: widget.bank.others.toString());
    _totalController = TextEditingController(text: widget.bank.total.toString());

    _invoiceTotal = widget.bank.invoiceTotal;

    _cashController.addListener(_calculateTotal);
    _onlineController.addListener(_calculateTotal);
    _chequeController.addListener(_calculateTotal);
    _othersController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _invoiceTotalController.dispose();
    _cashController.dispose();
    _onlineController.dispose();
    _chequeController.dispose();
    _othersController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    double cash = double.tryParse(_cashController.text) ?? 0.0;
    double online = double.tryParse(_onlineController.text) ?? 0.0;
    double cheque = double.tryParse(_chequeController.text) ?? 0.0;
    double others = double.tryParse(_othersController.text) ?? 0.0;

    double total = cash + online + cheque + others;
    _totalController.text = total.toString();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = AppDateFormat.format(picked);
      });
      await _calculateInvoiceTotal();
    }
  }

  Future<void> _calculateInvoiceTotal() async {
    if (_selectedDate == null) return;

    try {
      // Get all invoices
      final invoices = await _firebaseService.getInvoices().first;

      // Filter invoices by selected date
      final selectedDateString = AppDateFormat.format(_selectedDate!);
      final filteredInvoices = invoices.where((invoice) {
        return invoice.date == selectedDateString;
      }).toList();

      // Calculate total
      double total = 0.0;
      for (var invoice in filteredInvoices) {
        total += invoice.amount;
      }

      setState(() {
        _invoiceTotal = total;
        _invoiceTotalController.text = total.toString();
      });
    } catch (e) {
      log('Error calculating invoice total: $e');
    }
  }

  Future<void> _updateBank() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedBank = Bank(
        id: widget.bank.id,
        selectedDate: _dateController.text,
        invoiceTotal: _invoiceTotal,
        cash: double.parse(_cashController.text.isEmpty ? '0' : _cashController.text),
        online: double.parse(_onlineController.text.isEmpty ? '0' : _onlineController.text),
        cheque: double.parse(_chequeController.text.isEmpty ? '0' : _chequeController.text),
        others: double.parse(_othersController.text.isEmpty ? '0' : _othersController.text),
        total: double.parse(_totalController.text.isEmpty ? '0' : _totalController.text),
        createdAt: widget.bank.createdAt,
      );

      final success = await _firebaseService.updateBank(updatedBank);

      if (success) {
        if (mounted) {
          // Return the updated bank data and success flag
          Navigator.pop(context, {'success': true, 'bank': updatedBank});
        }
      } else {
        if (mounted) {
          // Return failure flag
          Navigator.pop(context, {'success': false});
        }
      }
    } catch (e) {
      log('Error updating bank: $e');
      if (mounted) {
        // Return failure flag
        Navigator.pop(context, {'success': false});
      }
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
        title: const Text('Edit Bank Collection'),
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
                  title: 'Date',
                  showTitle: true,
                  controller: _dateController,
                  hintText: 'Select Date',
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
                CustomTextFormField(
                  controller: _invoiceTotalController,
                  showTitle: true,
                  title: 'Invoice Total',
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _cashController,
                  showTitle: true,
                  title: 'Cash',
                  hintText: 'Enter cash amount',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _onlineController,
                  showTitle: true,
                  title: 'Online',
                  hintText: 'Enter online amount',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _chequeController,
                  showTitle: true,
                  title: 'Cheque',
                  hintText: 'Enter cheque amount',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _othersController,
                  showTitle: true,
                  title: 'Others',
                  hintText: 'Enter others amount',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _totalController,
                  showTitle: true,
                  title: 'Total',
                  hintText: '0.00',
                  keyboardType: TextInputType.number,
                  readOnly: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    label: 'Update',
                    borderRadius: 12,
                    isLoading: _isLoading,
                    onPressed: _updateBank,
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
