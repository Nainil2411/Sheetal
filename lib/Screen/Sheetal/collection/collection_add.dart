import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:sheetal/Screen/Sheetal/collection/collection.dart";
import "package:sheetal/Screen/Sheetal/customer/customer_module.dart";
import "package:sheetal/common/app_string.dart";
import "package:sheetal/common/common_font_style.dart";
import "package:sheetal/common/custom_appbar.dart";
import "package:sheetal/common/custom_color.dart";
import "package:sheetal/common/dropdown.dart";
import "package:sheetal/common/elevated_button.dart";
import "package:sheetal/common/textformfield.dart";
import "package:sheetal/utils/firebase_service.dart";

class AddCollectionScreen extends StatefulWidget {
  final String? prefillCustomerName;
  final double? prefillAmount;

  const AddCollectionScreen({
    super.key,
    this.prefillCustomerName,
    this.prefillAmount,
  });

  @override
  State<AddCollectionScreen> createState() => _AddCollectionScreenState();
}

class _AddCollectionScreenState extends State<AddCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _chequeDateController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _selectedPaymentMode;
  bool _isCustomerNameReadOnly = false;
  bool _isAmountReadOnly = false;
  bool _validateForm = false;
  String? _paymentModeError;
  List<Customer> _customers = [];
  Customer? _selectedCustomer;

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customersStream = _firebaseService.getSheetalCustomers();
      StreamSubscription? subscription;
      subscription = customersStream.listen((customers) {
        setState(() {
          _customers = customers;

          if (widget.prefillCustomerName != null && _customers.isNotEmpty) {
            _selectedCustomer = _customers.firstWhere(
                  (customer) => customer.name == widget.prefillCustomerName,
              orElse: () => _customers.first,
            );
          }
        });
        subscription?.cancel();
        setState(() {
          _isLoading = false;
        });
      });
    } catch (e) {
      log('Error loading customers: $e');
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
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

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
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(
      text: widget.prefillCustomerName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.prefillAmount != null ? widget.prefillAmount.toString() : '',
    );
    _dateController = TextEditingController();
    _chequeDateController = TextEditingController();
    _isCustomerNameReadOnly = widget.prefillCustomerName != null;
    _isAmountReadOnly = widget.prefillAmount != null;
    _loadCustomers();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _chequeDateController.dispose();
    super.dispose();
  }

  Future<void> _saveCollection() async {
    setState(() {
      _validateForm = true;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null && !_isCustomerNameReadOnly) {
      return;
    }

    if (_selectedPaymentMode == null || _selectedPaymentMode!.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final collection = Collection(
        customerName: _isCustomerNameReadOnly
            ? _customerNameController.text.trim()
            : _selectedCustomer!.name,
        amount: double.parse(_amountController.text.trim()),
        paymentMode: _selectedPaymentMode!,
        date: _dateController.text,
        // Make cheque date optional - only save if provided
        chequeDate: _selectedPaymentMode == 'Cheque' && _chequeDateController.text.isNotEmpty
            ? _chequeDateController.text
            : null,
      );

      final collectionId = await _firebaseService.addCollection(collection);

      if (collectionId != null) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      log("Error saving collection: $e");
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
        title: const Text(AppStrings.addcollection),
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
                  title: AppStrings.date,
                  showTitle: true,
                  controller: _dateController,
                  hintText: AppStrings.selectDate,
                  showBorders: true,
                  borderColor: CustomColors.textSecondary.withOpacity(0.5),
                  readOnly: true,
                  onTap: () {
                    _selectDate(context);
                  },
                  suffixIcon: Icon(Icons.calendar_today),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select a date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _isCustomerNameReadOnly
                    ? CustomTextFormField(
                  showTitle: true,
                  title: AppStrings.customername,
                  hintText: AppStrings.customername,
                  controller: _customerNameController,
                  readOnly: true,
                  enabled: false,
                )
                    : CustomDropdown<Customer>(
                  showTitle: true,
                  title: AppStrings.customername,
                  hint: AppStrings.selectcustomer,
                  value: _selectedCustomer,
                  getSearchText: (customer) => customer.name,
                  items: _customers.isEmpty
                      ? [
                    const DropdownMenuItem<Customer>(
                      value: null,
                      child: Text(AppStrings.nocustomer),
                    ),
                  ]
                      : _customers.map((customer) {
                    return DropdownMenuItem<Customer>(
                      value: customer,
                      child: Text(customer.name),
                    );
                  }).toList(),
                  onChanged: (Customer? newValue) {
                    setState(() {
                      _selectedCustomer = newValue;
                      if (newValue != null) {
                        _customerNameController.text = newValue.name;
                      }
                    });
                  },
                  validator: (value) => _validateForm && value == null
                      ? AppStrings.selectcustomer
                      : null,
                  selectedItemBuilder: (customer) =>
                      Text(customer?.name ?? AppStrings.selectcustomer),
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  showTitle: true,
                  title: AppStrings.amount,
                  hintText: AppStrings.amountrequire,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  controller: _amountController,
                  readOnly: _isAmountReadOnly,
                  enabled: !_isAmountReadOnly,
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
                      _selectedPaymentMode = newValue;
                      _paymentModeError = null;
                      if (newValue != 'Cheque') {
                        _chequeDateController.clear();
                      }
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

                // Optional Cheque Date Field
                if (_selectedPaymentMode == 'Cheque') ...[
                  const SizedBox(height: 16),
                  CustomTextFormField(
                    title: "Cheque Date (Optional)",
                    showTitle: true,
                    controller: _chequeDateController,
                    hintText: "Select Cheque Date (Optional)",
                    showBorders: true,
                    borderColor: CustomColors.textSecondary.withOpacity(0.5),
                    readOnly: true,
                    onTap: () {
                      _selectChequeDate(context);
                    },
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You can add the cheque date later from Finance Portfolio",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: CustomColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    onPressed: _saveCollection,
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