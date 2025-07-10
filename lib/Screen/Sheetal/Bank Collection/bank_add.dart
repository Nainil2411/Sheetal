import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Bank%20Collection/bank.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dateformat.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class AddBankScreen extends StatefulWidget {
  const AddBankScreen({super.key});

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _invoiceTotalController = TextEditingController();
  final _cashController = TextEditingController();
  final _onlineController = TextEditingController();
  final _chequeController = TextEditingController();
  final _othersController = TextEditingController();
  final _totalController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  DateTime? _selectedDate;
  double _invoiceTotal = 0.0;

  @override
  void initState() {
    super.initState();
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
      final selectedDateString = AppDateFormat.format(_selectedDate!);

      // Get all invoices for the selected date
      final invoices = await _firebaseService.getInvoices().first;
      final filteredInvoices = invoices.where((invoice) {
        return invoice.date == selectedDateString;
      }).toList();

      // Calculate total invoice amount for the date
      double totalInvoiceAmount = 0.0;
      for (var invoice in filteredInvoices) {
        totalInvoiceAmount += invoice.amount;
      }

      // Get all existing bank collections for the same date
      final bankCollections = await _firebaseService.getBanks().first;
      final existingCollections = bankCollections.where((bank) {
        return bank.selectedDate == selectedDateString;
      }).toList();

      // Calculate total already collected amount for the date
      double totalCollectedAmount = 0.0;
      for (var bank in existingCollections) {
        totalCollectedAmount += bank.total;
      }

      // Calculate remaining amount (Invoice Total - Already Collected)
      double remainingAmount = totalInvoiceAmount - totalCollectedAmount;

      // Ensure remaining amount is not negative
      remainingAmount = remainingAmount < 0 ? 0 : remainingAmount;

      setState(() {
        _invoiceTotal = remainingAmount;
        _invoiceTotalController.text = remainingAmount.toString();
      });

      // Optional: Show a message if no amount is remaining
      if (remainingAmount == 0 && totalInvoiceAmount > 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All invoice amounts for $selectedDateString have been collected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      log('Error calculating invoice total: $e');
    }
  }
  Future<void> _saveBank() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bank = Bank(
        selectedDate: _dateController.text,
        invoiceTotal: _invoiceTotal,
        cash: double.parse(_cashController.text.isEmpty ? '0' : _cashController.text),
        online: double.parse(_onlineController.text.isEmpty ? '0' : _onlineController.text),
        cheque: double.parse(_chequeController.text.isEmpty ? '0' : _chequeController.text),
        others: double.parse(_othersController.text.isEmpty ? '0' : _othersController.text),
        total: double.parse(_totalController.text.isEmpty ? '0' : _totalController.text),
      );

      final bankId = await _firebaseService.addBank(bank);

      if (bankId != null) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      log('Error saving bank: $e');
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
        title: const Text('Add Bank Collection'),
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
                    label: 'Save',
                    borderRadius: 12,
                    isLoading: _isLoading,
                    onPressed: _saveBank,
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
