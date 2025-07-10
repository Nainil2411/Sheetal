import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice.dart';
import 'package:sheetal/Screen/Sheetal/Invoices/invoice_edit.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Invoice _invoice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
  }

  Future<void> _deleteInvoice() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          final success = await _firebaseService.deleteInvoice(_invoice.id!);
          if (mounted) {
            if (success) {
              Navigator.pop(context, true);
            }
          }
        } catch (e) {
          log('Error deleting invoice: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }
  Future<void> _editInvoice() async {
    final result = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(
        builder: (context) => EditInvoiceScreen(invoice: _invoice),
      ),
    );

    if (result != null) {
      setState(() {
        _invoice = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(AppStrings.invoicedetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editInvoice,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteInvoice,
          ),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: DetailCard(
          amount: _invoice.amount,
          isExpense: true,
          amountLabel: AppStrings.invoiceamount,
          detailRows: [
            DetailRow(label: AppStrings.customer, value: _invoice.customerName),
            DetailRow(label: AppStrings.category, value: _invoice.categoryName),
            DetailRow(label: AppStrings.date, value: _invoice.date),
          ],
        ),
      ),
    );
  }
}
