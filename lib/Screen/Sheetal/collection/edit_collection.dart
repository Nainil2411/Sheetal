import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/dropdown.dart';
import 'package:sheetal/common/elevated_button.dart';
import 'package:sheetal/common/textformfield.dart';
import 'package:sheetal/utils/firebase_service.dart';

class EditCollectionScreen extends StatefulWidget {
  final Collection collection;

  const EditCollectionScreen({super.key, required this.collection});

  @override
  State<EditCollectionScreen> createState() => _EditCollectionScreenState();
}

class _EditCollectionScreenState extends State<EditCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _chequeDateController; // New controller for cheque date
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  late String _selectedPaymentMode;
  final List<String> _paymentModes = [
    AppStrings.cash,
    AppStrings.online,
    AppStrings.cheque,
    AppStrings.upi,
    AppStrings.banktransfer,
    AppStrings.other
  ];

  @override
  void initState() {
    super.initState();
    _customerNameController =
        TextEditingController(text: widget.collection.customerName);
    _amountController =
        TextEditingController(text: widget.collection.amount.toString());
    _selectedPaymentMode = widget.collection.paymentMode;
    _dateController = TextEditingController(text: widget.collection.date);

    // Initialize cheque date controller
    // If you have chequeDate in your Collection model, initialize it here:
    // _chequeDateController = TextEditingController(text: widget.collection.chequeDate ?? '');
    // Otherwise, initialize empty:
    _chequeDateController = TextEditingController();
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
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // New method for selecting cheque date
  Future<void> _selectChequeDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _chequeDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _chequeDateController.dispose(); // Dispose cheque date controller
    super.dispose();
  }

  Future<void> _updateCollection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCollection = Collection(
        id: widget.collection.id,
        customerName: _customerNameController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        paymentMode: _selectedPaymentMode,
        createdAt: widget.collection.createdAt,
        date: _dateController.text,
        // You might want to add chequeDate to your Collection model if needed
        // chequeDate: _selectedPaymentMode == AppStrings.cheque ? _chequeDateController.text : null,
      );

      final success =
      await _firebaseService.updateCollection(updatedCollection);

      if (success) {
        if (mounted) {
          Navigator.pop(context, updatedCollection);
        }
      }
    } catch (e) {
      log('Error updating collection: $e');
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
        title: Text(AppStrings.editcollection),
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
                  controller: _customerNameController,
                  showTitle: true,
                  title: AppStrings.customername,
                  readOnly: true,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  showTitle: true,
                  title: AppStrings.amount,
                  hintText: AppStrings.amountrequire,
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
                CustomDropdown<String>(
                  hint: AppStrings.selectPaymentMethod,
                  value: _selectedPaymentMode,
                  items: _paymentModes.map((String mode) {
                    return DropdownMenuItem<String>(
                      value: mode,
                      child: Text(mode),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedPaymentMode = newValue;

                        // Clear cheque date when payment mode changes from Cheque to something else
                        if (newValue != AppStrings.cheque) {
                          _chequeDateController.clear();
                        }
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppStrings.paymentmethodrequire;
                    }
                    return null;
                  },
                  showTitle: true,
                  title: AppStrings.paymentmethod,
                ),
                const SizedBox(height: 16),

                // Conditional Cheque Date Field
                if (_selectedPaymentMode == AppStrings.cheque) ...[
                  CustomTextFormField(
                    title: "Cheque Date", // You might want to add this to AppStrings
                    showTitle: true,
                    controller: _chequeDateController,
                    hintText: "Select Cheque Date", // You might want to add this to AppStrings
                    showBorders: true,
                    readOnly: true,
                    onTap: () {
                      _selectChequeDate(context);
                    },
                    suffixIcon: Icon(Icons.calendar_today),
                    validator: (value) {
                      if (_selectedPaymentMode == AppStrings.cheque && (value == null || value.trim().isEmpty)) {
                        return 'Please select cheque date';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

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
                    isLoading: _isLoading,
                    borderRadius: 12,
                    onPressed: _updateCollection,
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