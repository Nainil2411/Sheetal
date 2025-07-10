import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase.dart';
import 'package:sheetal/Screen/Sheetal/Purchase/purchase_edit.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final Purchase purchase;

  const PurchaseDetailScreen({super.key, required this.purchase});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Purchase _purchase;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _purchase = widget.purchase;
  }

  Future<void> _deletePurchase() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          final success = await _firebaseService.deletePurchase(_purchase.id!);
          if (mounted) {
            if (success) {
              Navigator.pop(context, true);
            }
          }
        } catch (e) {
          log('Error deleting purchase: $e');
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

  Future<void> _editPurchase() async {
    final result = await Navigator.push<Purchase>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPurchaseScreen(purchase: _purchase),
      ),
    );

    if (result != null) {
      setState(() {
        _purchase = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Purchase Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editPurchase,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deletePurchase,
          ),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: DetailCard(
          amount: _purchase.amount,
          isExpense: true,
          amountLabel: 'Purchase Amount',
          detailRows: [
            DetailRow(label: 'Category', value: _purchase.categoryName),
            DetailRow(label: 'Date', value: _purchase.date),
          ],
        ),
      ),
    );
  }
}