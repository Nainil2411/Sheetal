import 'package:flutter/material.dart';
import 'common_font_style.dart';
import 'custom_color.dart';
import 'amount_format.dart';

class DetailCard extends StatelessWidget {
  final double amount;
  final String amountLabel;
  final bool isExpense;
  final List<DetailRow> detailRows;
  final EdgeInsets? margin;

  const DetailCard({
    super.key,
    required this.amount,
    this.amountLabel = 'Amount',
    required this.isExpense,
    required this.detailRows,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Card (Amount Display)
        Card(
          color: isExpense
              ? Colors.redAccent.withOpacity(0.3)
              : CustomColors.green1.withOpacity(0.2),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          margin: margin ?? const EdgeInsets.only(right: 13, left: 13),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      amountLabel,
                      style: AppTextStyles.labelgrey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${Global.formatAmount(amount)}',
                      style: isExpense
                          ? AppTextStyles.redtextlarge
                          : AppTextStyles.greentextlarge,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom Card (Details)
        Card(
          elevation: 1,
          margin: margin != null
              ? EdgeInsets.only(
              left: margin!.left + 0.5,
              right: margin!.right + 0.5
          )
              : const EdgeInsets.only(left: 13.5, right: 13.5),
          color: CustomColors.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildDetailRowsWithDividers(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDetailRowsWithDividers() {
    final List<Widget> widgets = [];

    for (int i = 0; i < detailRows.length; i++) {
      widgets.add(detailRows[i]);

      // Add divider after each row except the last one
      if (i < detailRows.length - 1) {
        widgets.add(const Divider());
      }
    }

    return widgets;
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.labelgrey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
