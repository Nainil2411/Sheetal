import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Sheetal/collection/collection.dart';
import 'package:sheetal/Screen/Sheetal/collection/edit_collection.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/utils/firebase_service.dart';
import 'package:sheetal/utils/utility.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Collection _collection;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _collection = widget.collection;
  }

  Future<void> _deleteCollection() async {
    await Utility.showDeleteConfirmationDialog(
      context: context,
      onConfirm: () async {
        setState(() {
          _isLoading = true;
        });

        try {
          final success =
          await _firebaseService.deleteCollection(_collection.id!);

          if (success) {
            if (mounted) {
              Navigator.pop(context, true);
            }
          }
        } catch (e) {
          log("Error deleting collection: $e");
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

  Future<void> _editCollection() async {
    final result = await Navigator.push<Collection>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCollectionScreen(collection: _collection),
      ),
    );

    if (result != null) {
      setState(() {
        _collection = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<DetailRow> detailRows = [
      DetailRow(
          label: AppStrings.customer,
          value: _collection.customerName),
      DetailRow(
          label: AppStrings.paymentmethod,
          value: _collection.paymentMode),
      DetailRow(label: AppStrings.date, value: _collection.date),
    ];

    // Add cheque date if it exists
    if (_collection.paymentMode.toLowerCase() == 'cheque') {
      detailRows.add(
        DetailRow(
          label: "Cheque Date",
          value: _collection.chequeDate ?? "Not Set",
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(AppStrings.collectiondetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading ? null : _editCollection,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteCollection,
          ),
        ],
      ),
      body: _isLoading
          ? Utility.circleloading()
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: DetailCard(
          amount: _collection.amount,
          amountLabel: AppStrings.amount,
          isExpense: false,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          detailRows: detailRows,
        ),
      ),
    );
  }
}