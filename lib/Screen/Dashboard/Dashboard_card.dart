import 'package:flutter/material.dart';
import 'package:sheetal/Screen/Dashboard/finance_portfolio.dart';
import 'package:sheetal/Screen/Dashboard/scpl.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/app_images.dart';
import 'package:sheetal/common/app_string.dart';
import 'package:sheetal/common/white&black_card.dart';

class FinanceCardsPage extends StatelessWidget {
  final double totalRevenue;
  final double totalCollection;
  final double totalExpenses;
  final double totalPurchase;
  final double profit;
  final double netProfit;

  const FinanceCardsPage({
    super.key,
    required this.totalRevenue,
    required this.totalCollection,
    required this.totalExpenses,
    required this.totalPurchase,
    required this.profit,
    required this.netProfit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: buildCard(
                  isBlackCard: true,
                  value: Global.formatAmount(totalRevenue),
                  subtitle: AppStrings.totalrevenue,
                  imagePath: AppImages.revenue,
                ),
              ),
              const SizedBox(width: 25),
              Expanded(
                child: buildCard(
                  value: Global.formatAmount(totalCollection),
                  subtitle: AppStrings.totalcollection,
                  imagePath: AppImages.collection,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: buildCard(
                  value: Global.formatAmount(totalExpenses),
                  subtitle: AppStrings.totalexpense,
                  imagePath: AppImages.expense,
                  isBlackCard: true,
                ),
              ),
              const SizedBox(width: 25),
              Expanded(
                child: buildCard(
                  value: Global.formatAmount(totalPurchase),
                  subtitle: "Total Purchase",
                  icon: Icons.shopping_cart,
                  isBlackCard: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: buildCard(
                  value: Global.formatAmount(profit),
                  subtitle: AppStrings.profit,
                  icon: profit <= 0 ? Icons.trending_down : Icons.trending_up,
                  isBlackCard: true,
                ),
              ),
              const SizedBox(width: 25),
              Expanded(
                child: buildCard(
                  value: Global.formatAmount(netProfit),
                  subtitle: AppStrings.netprofit,
                  icon:
                      netProfit <= 0 ? Icons.trending_down : Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerInvoiceHistoryScreen(),
                      ),
                    );
                  },
                  child: buildCard(
                    hideCurrencySymbol: true,
                    value: AppStrings.scpl,
                    subtitle: 'Detailed SCPL',
                    icon: Icons.account_balance_wallet_outlined,
                    isBlackCard: true,
                  ),
                ),
              ),
              const SizedBox(width: 25),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FinancePortfolioScreen(),
                      ),
                    );
                  },
                  child: buildCard(
                    hideCurrencySymbol: true,
                    value: AppStrings.portfolio,
                    subtitle: AppStrings.viewall,
                    icon: Icons.pie_chart,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
