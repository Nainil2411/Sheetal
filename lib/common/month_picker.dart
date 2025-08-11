import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetal/common/custom_color.dart';

// Public helper to show a Month/Year picker dialog and return the selected month
Future<DateTime?> showMonthYearPicker(BuildContext context,
    {DateTime? initialDate, DateTime? latestAllowed}) {
  final DateTime now = DateTime.now();
  final DateTime latest = DateTime(
    (latestAllowed ?? now).year,
    (latestAllowed ?? now).month,
  );
  final DateTime init = initialDate ?? now;
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return _MonthYearPickerDialog(
        initialDate: init,
        latestAllowed: latest,
      );
    },
  );
}

class MonthPickerWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onMonthChanged;

  const MonthPickerWidget({
    super.key,
    required this.selectedDate,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime latestAllowed = DateTime(now.year, now.month);
    final bool canGoNext = DateTime(selectedDate.year, selectedDate.month)
        .isBefore(latestAllowed);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CustomColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CustomColors.textSecondary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final previousMonth = DateTime(
                selectedDate.year,
                selectedDate.month - 1,
              );
              onMonthChanged(previousMonth);
            },
          ),
          GestureDetector(
            onTap: () => _showMonthYearPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CustomColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: CustomColors.textSecondary.withOpacity(0.3),
                ),
              ),
              child: Text(
                DateFormat('MMMM yyyy').format(selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CustomColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: canGoNext
                ? () {
                    final nextMonth = DateTime(
                      selectedDate.year,
                      selectedDate.month + 1,
                    );
                    if (!DateTime(nextMonth.year, nextMonth.month)
                        .isAfter(latestAllowed)) {
                      onMonthChanged(nextMonth);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showMonthYearPicker(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return _MonthYearPickerDialog(
          initialDate: selectedDate,
          latestAllowed: DateTime.now(),
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      onMonthChanged(picked);
    }
  }
}

class _MonthYearPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime latestAllowed;

  const _MonthYearPickerDialog({required this.initialDate, required this.latestAllowed});

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    final DateTime latest = DateTime(widget.latestAllowed.year, widget.latestAllowed.month);
    final DateTime init = DateTime(widget.initialDate.year, widget.initialDate.month);
    final DateTime coerced = init.isAfter(latest) ? latest : init;
    selectedYear = coerced.year;
    selectedMonth = coerced.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CustomColors.background,
      title: const Text(
        'Select Month & Year',
        style: TextStyle(color: CustomColors.textPrimary),
      ),
      content: SizedBox(
        width: 300,
        height: 200,
        child: Column(
          children: [
            // Year picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Year:',
                    style: TextStyle(
                      fontSize: 16,
                      color: CustomColors.textPrimary,
                    )),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          selectedYear--;
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      selectedYear.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CustomColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: selectedYear < widget.latestAllowed.year
                          ? () {
                              setState(() {
                                selectedYear++;
                                if (selectedYear == widget.latestAllowed.year &&
                                    selectedMonth > widget.latestAllowed.month) {
                                  selectedMonth = widget.latestAllowed.month;
                                }
                              });
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Month picker
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final monthName = DateFormat('MMM').format(DateTime(2023, month));
                  final isSelected = month == selectedMonth;
                  final bool isDisabled = selectedYear > widget.latestAllowed.year ||
                      (selectedYear == widget.latestAllowed.year &&
                          month > widget.latestAllowed.month);

                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () {
                            setState(() {
                              selectedMonth = month;
                            });
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CustomColors.textPrimary
                            : CustomColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDisabled
                              ? CustomColors.textSecondary.withOpacity(0.2)
                              : CustomColors.textSecondary.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          monthName,
                          style: TextStyle(
                            color: isSelected
                                ? CustomColors.background
                                : isDisabled
                                    ? CustomColors.textSecondary.withOpacity(0.5)
                                    : CustomColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel',
              style: TextStyle(color: CustomColors.textPrimary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(DateTime(selectedYear, selectedMonth));
          },
          child: const Text('OK',
              style: TextStyle(color: CustomColors.textPrimary)),
        ),
      ],
    );
  }
}