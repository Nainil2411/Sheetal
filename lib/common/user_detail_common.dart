import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sheetal/common/custom_color.dart';
import 'package:sheetal/common/common_font_style.dart';
import 'package:sheetal/common/app_string.dart';
import '../utils/utility.dart';

class ShadowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const ShadowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: CustomColors.background,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.
            withOpacity(0.2),
            spreadRadius: 3,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

/// A section title with an optional divider
class SectionTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final bool showDivider;

  const SectionTitle({
    super.key,
    required this.title,
    this.style,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: style ?? AppTextStyles.headline4,
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}

/// A row displaying a label and a value
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final double labelWidth;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: AppTextStyles.subtitleSmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A financial display item showing value with color
class FinancialItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool fullWidth;

  const FinancialItem({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.subtitleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// A transaction item card showing transaction details
class TransactionItem extends StatelessWidget {
  final double amount;
  final DateTime date;
  final String description;
  final bool isCredit;

  const TransactionItem({
    super.key,
    required this.amount,
    required this.date,
    required this.description,
    required this.isCredit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      color: CustomColors.background,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: CustomColors.textPrimary),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          isCredit ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? CustomColors.green1 : CustomColors.error,
          ),
        ),
        title: Text(
          description,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          dateFormat.format(date),
          style: AppTextStyles.subtitleSmall,
        ),
        trailing: Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCredit ? CustomColors.green1 : CustomColors.error,
          ),
        ),
      ),
    );
  }
}

/// A loading placeholder that can be shown while data is loading
class LoadingPlaceholder extends StatelessWidget {
  final Color color;

  const LoadingPlaceholder({
    super.key,
    this.color = CustomColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Utility.circleloading();
  }
}

/// A user avatar with initial letter
class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 30,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: CustomColors.textPrimary,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '',
        style: AppTextStyles.headline1white,
      ),
    );
  }
}

/// A tabbed container with credit and debit transactions
class TransactionTabs extends StatelessWidget {
  final String userId;
  final Function(String) getCreditTransactions;
  final Function(String) getDebitTransactions;

  const TransactionTabs({
    super.key,
    required this.userId,
    required this.getCreditTransactions,
    required this.getDebitTransactions,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: CustomColors.textPrimary,
            unselectedLabelColor: CustomColors.textSecondary,
            indicatorColor: CustomColors.textPrimary,
            tabs: [
              Tab(text: AppStrings.credit),
              Tab(text: AppStrings.debit),
            ],
          ),
          SizedBox(
            height: 300,
            child: TabBarView(
              children: [
                _buildTransactionList(true),
                _buildTransactionList(false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool isCredit) {
    return StreamBuilder<dynamic>(
      stream: isCredit
          ? getCreditTransactions(userId)
          : getDebitTransactions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder();
        }

        if (snapshot.hasError) {
          return Center(child: Text(AppStrings.genericError + snapshot.error.toString()));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text(AppStrings.nocreditdebit));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final amount = data['amount'] as num;
            final date = data['date'];
            final description = data['paymentMode'] as String? ?? 'No paymentMode';

            return TransactionItem(
              amount: amount.toDouble(),
              date: date is DateTime ? date : (date as dynamic).toDate(),
              description: description,
              isCredit: isCredit,
            );
          },
        );
      },
    );
  }
}