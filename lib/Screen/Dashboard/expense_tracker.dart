import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetal/common/amount_format.dart';
import 'package:sheetal/common/custom_color.dart';

class ExpenseTrackerCard extends StatefulWidget {
  final double totalExpense;
  final double estimatedExpense;
  final double initialMaxBudget;

  const ExpenseTrackerCard({
    super.key,
    required this.totalExpense,
    required this.estimatedExpense,
    required this.initialMaxBudget,
  });

  @override
  State<ExpenseTrackerCard> createState() => _ExpenseTrackerCardState();
}

class _ExpenseTrackerCardState extends State<ExpenseTrackerCard> {
  double? _maxBudget;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxBudget = prefs.getDouble('budgetLimit') ?? widget.initialMaxBudget;
    });
  }

  Future<void> _saveBudget(double value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('budgetLimit', value);
  }

  @override
  Widget build(BuildContext context) {
    if (_maxBudget == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final double expensePercentage = (_maxBudget! > 0)
        ? (widget.totalExpense / _maxBudget! * 100).clamp(0, 100)
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildSemiCircularDotIndicator(
                        percentage: expensePercentage,
                        radius: 180,
                        totalDots: 36,
                      ),
                      _buildSemiCircularDotIndicator(
                        percentage: expensePercentage,
                        radius: 130,
                        totalDots: 30,
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        'Summary',
                        style: TextStyle(
                          fontSize: 16,
                          color: CustomColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${expensePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CustomColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Total Expense',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Text(
                '₹${Global.formatAmount(widget.totalExpense)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Estimated Expense',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Text(
                '₹${Global.formatAmount(_maxBudget!)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildBudgetProgressBar(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${Global.formatAmount(widget.totalExpense)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Budget: ₹${Global.formatAmount(_maxBudget!)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBudgetSlider(),
        ],
      ),
    );
  }

  Widget _buildSemiCircularDotIndicator({
    required double percentage,
    required double radius,
    required int totalDots,
  }) {
    const double dotSize = 10;
    final int filledDots = (percentage / 100 * totalDots).round();
    final double paddedRadius = radius + dotSize;

    return SizedBox(
      width: paddedRadius * 2,
      height: paddedRadius,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(totalDots, (index) {
          final double angle = pi * (index / (totalDots - 1)) - pi;
          final double x = radius * cos(angle);
          final double y = radius * sin(angle);
          final bool isFilled = index < filledDots;
          final double opacity = 0.5 + 0.5 * (index / (totalDots - 1));

          return Positioned(
            left: paddedRadius + x - (dotSize / 2),
            top: paddedRadius + y - (dotSize / 2),
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled
                    ? Colors.black.withOpacity(opacity)
                    : Colors.black.withOpacity(0.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBudgetProgressBar() {
    final double progressPercentage = (_maxBudget! > 0)
        ? (widget.totalExpense / _maxBudget!).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Budget Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressPercentage,
            child: Container(
              decoration: BoxDecoration(
                color: _getProgressColor(progressPercentage),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Set Budget Limit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CustomColors.textPrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '₹${Global.formatAmount(_maxBudget!)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.background,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: CustomColors.textPrimary,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: CustomColors.textPrimary,
            overlayColor: Colors.black.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            min: 1,
            max: 1000000,
            value: _maxBudget!,
            divisions: 100,
            onChanged: (value) {
              setState(() {
                _maxBudget = value;
              });
              _saveBudget(value);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('₹1'),
            Text('₹10,00,000'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPresetButton('₹10K', 10000),
            _buildPresetButton('₹50K', 50000),
            _buildPresetButton('₹1L', 100000),
            _buildPresetButton('₹5L', 500000),
            _buildPresetButton('₹10L', 1000000),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, double value) {
    final bool isSelected = (_maxBudget == value);

    return GestureDetector(
      onTap: () {
        setState(() {
          _maxBudget = value;
        });
        _saveBudget(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? CustomColors.textPrimary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color:
                isSelected ? CustomColors.background : CustomColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 0.5) {
      return CustomColors.green1;
    } else if (percentage < 0.75) {
      return Colors.orange;
    } else {
      return CustomColors.error1;
    }
  }
}
