import 'package:flutter/material.dart';

import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/custom_appbar.dart';
import 'package:sheetal/common/detail_card.dart';
import 'package:sheetal/common/elevated_button.dart';
import '../collection/collection_add.dart';

class PendingCollectionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pendingCollection;

  const PendingCollectionDetailScreen({
    super.key,
    required this.pendingCollection,
  });

  @override
  Widget build(BuildContext context) {
    final List<DetailRow> customerDetailRows = [
      DetailRow(
        label: AppStrings.customername,
        value: pendingCollection['customerName'],
      ),
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text(AppStrings.collectiondetail),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailCard(
                amount: pendingCollection['pendingAmount'],
                amountLabel: AppStrings.pendingamount,
                isExpense: true,
                detailRows: customerDetailRows,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    label: AppStrings.addcollection,
                    borderRadius: 12,
                    onPressed: () => _navigateToAddCollection(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAddCollection(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCollectionScreen(
          prefillCustomerName: pendingCollection['customerName'],
          prefillAmount: pendingCollection['pendingAmount'],
        ),
      ),
    );

    if (result == true) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    }
  }
}
