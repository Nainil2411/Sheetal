import 'package:flutter/material.dart';
import 'package:sheetal/common/amount_format.dart';

class MinimalCalculationCard extends StatelessWidget {
  final double totalPurchase;
  final double totalCredit;
  final double totalScheme;
  final double totalDiscount;

  const MinimalCalculationCard({
    super.key,
    required this.totalPurchase,
    required this.totalCredit,
    required this.totalScheme,
    required this.totalDiscount,
  });

  double get netValue => totalPurchase - totalCredit - totalScheme - totalDiscount;

  @override
  Widget build(BuildContext context) {
    final isPositive = netValue >= 0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf3f4f6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPositive ? 'Positive' : 'Negative',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isPositive ? const Color(0xFF059669) : const Color(0xFFdc2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          
          // Content Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _SimpleRow('Purchase', totalPurchase, isPositive: true),
                _SimpleRow('Credit', totalCredit, isPositive: false),
                _SimpleRow('Scheme', totalScheme, isPositive: false),
                _SimpleRow('Discount', totalDiscount, isPositive: false),
                
                const SizedBox(height: 16),
                
                // Final divider
                Container(
                  height: 1,
                  color: Colors.grey[300],
                ),
                
                const SizedBox(height: 16),
                
                // Net Value Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '₹${Global.formatAmount(netValue.abs())}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? const Color(0xFF059669) : const Color(0xFFdc2626),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isPositive;

  const _SimpleRow(this.label, this.value, {required this.isPositive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6b7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}₹${Global.formatAmount(value)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isPositive ? const Color(0xFF059669) : const Color(0xFF6b7280),
            ),
          ),
        ],
      ),
    );
  }
}


