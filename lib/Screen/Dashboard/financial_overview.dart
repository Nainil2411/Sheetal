import 'package:flutter/material.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_color.dart';

class BubbleVisualization extends StatelessWidget {
  final double totalRevenue;
  final double totalCollection;
  final double totalExpenses;
  final double totalPurchase;
  final double totalDiscount;
  final double profit;
  final double netProfit;

  const BubbleVisualization({
    super.key,
    required this.totalRevenue,
    required this.totalCollection,
    required this.totalExpenses,
    required this.totalPurchase,
    required this.totalDiscount,
    required this.profit,
    required this.netProfit,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> values = [
      totalRevenue.abs(),
      totalCollection.abs(),
      totalPurchase.abs(),
      totalDiscount.abs(),
      netProfit.abs(),
    ];

    final double maxValue = values.reduce((a, b) => a > b ? a : b);
    final double revenueSize = _calculateBubbleSize(totalRevenue, maxValue);
    final double collectionSize =
        _calculateBubbleSize(totalCollection, maxValue);
    final double purchaseSize = _calculateBubbleSize(totalPurchase, maxValue);
    final double discountSize = _calculateBubbleSize(totalDiscount, maxValue);
    final double netProfitSize = _calculateBubbleSize(netProfit, maxValue);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Revenue bubble
                Positioned(
                  left: 40,
                  top: 70,
                  child: _buildBubble(
                    size: revenueSize,
                    color: CustomColors.textPrimary,
                    label: 'Revenue',
                    value: totalRevenue,
                  ),
                ),
                // Collection bubble
                Positioned(
                  right: 50,
                  top: 140,
                  child: _buildBubble(
                    size: collectionSize,
                    color: CustomColors.textPrimary.withOpacity(0.7),
                    label: 'Collection',
                    value: totalCollection,
                  ),
                ),
                // Purchase bubble
                Positioned(
                  left: 50,
                  bottom: 10,
                  child: _buildBubble(
                    size: purchaseSize,
                    color: CustomColors.textPrimary.withOpacity(0.5),
                    label: 'Purchase',
                    value: totalPurchase,
                  ),
                ),
                // Discount bubble
                Positioned(
                  left: 170,
                  bottom: 100,
                  child: _buildBubble(
                    size: discountSize,
                    color: CustomColors.textPrimary.withOpacity(0.45),
                    label: 'Discount',
                    value: totalDiscount,
                  ),
                ),
                // Net Profit bubble
                Positioned(
                  right: 70,
                  bottom: 50,
                  child: _buildBubble(
                    size: netProfitSize,
                    color: CustomColors.textPrimary.withOpacity(0.3),
                    label: 'Net Profit',
                    value: netProfit,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildLegend(),
        ],
      ),
    );
  }

  double _calculateBubbleSize(double value, double maxValue) {
    const double minSize = 80.0;
    const double maxSize = 180.0;
    if (value < 0) {
      return minSize;
    }
    if (maxValue == 0 || maxValue < 0.001) return minSize;
    double proportion = value / maxValue;
    return minSize + (proportion * (maxSize - minSize));
  }

  Widget _buildBubble({
    required double size,
    required Color color,
    required String label,
    required double value,
  }) {
    final safeSize = size.clamp(60.0, 200.0);
    final String formattedAmount = '₹${Global.formatAmount(value)}';

    return Container(
      width: safeSize,
      height: safeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formattedAmount,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CustomColors.background,
                fontWeight: FontWeight.bold,
                fontSize: safeSize * 0.16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          color: CustomColors.textPrimary,
          label: 'Revenue',
          value: totalRevenue,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          color: CustomColors.textPrimary.withOpacity(0.7),
          label: 'Collection',
          value: totalCollection,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          color: CustomColors.textPrimary.withOpacity(0.5),
          label: 'Purchase',
          value: totalPurchase,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          color: CustomColors.textPrimary.withOpacity(0.45),
          label: 'Discount',
          value: totalDiscount,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          color: CustomColors.textPrimary.withOpacity(0.3),
          label: 'Net Profit',
          value: netProfit,
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double value,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '₹${Global.formatAmount(value)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
