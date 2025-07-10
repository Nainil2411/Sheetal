import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_string.dart';
import 'common_font_style.dart';
import 'custom_color.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const CustomDateRangePicker({
    super.key,
    this.initialDateRange,
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.initialDateRange?.start ?? DateTime.now();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        _startDate = date;
        _endDate = null;
      } else {
        if (date.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
        1,
      );
    });
  }

  bool _isSelected(DateTime date) {
    if (_startDate == null) return false;

    if (_endDate == null) {
      return date.year == _startDate!.year &&
          date.month == _startDate!.month &&
          date.day == _startDate!.day;
    }

    return (date.isAfter(_startDate!) || _isSameDay(date, _startDate!)) &&
        (date.isBefore(_endDate!) || _isSameDay(date, _endDate!));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: CustomColors.textPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: CustomColors.background),
                    onPressed: _previousMonth,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    style: AppTextStyles.whitebuttonText
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: CustomColors.background),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) =>
                    SizedBox(
                      width: 30,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style:  TextStyle(
                          color: CustomColors.background.withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                ).toList(),
              ),
            ),
            const SizedBox(height: 8),
            _buildCalendarGrid(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child:  Text(
                      AppStrings.cancel,
                      style: TextStyle(color: CustomColors.background.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CustomColors.textPrimary,
                    ),
                    onPressed: _startDate != null && _endDate != null
                        ? () {
                      Navigator.pop(
                        context,
                        DateTimeRange(
                          start: _startDate!,
                          end: _endDate!,
                        ),
                      );
                    }
                        : null,
                    child:  Text(AppStrings.applyfilter,style: TextStyle(color: CustomColors.background),),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday % 7;
    final lastDayPrevMonth = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    final List<Widget> dayWidgets = [];

    for (int i = 0; i < firstWeekdayOfMonth; i++) {
      final day = lastDayPrevMonth - firstWeekdayOfMonth + i + 1;
      final date = DateTime(_currentMonth.year, _currentMonth.month - 1, day);
      dayWidgets.add(_buildDayWidget(day.toString(), date, true));
    }
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      dayWidgets.add(_buildDayWidget(i.toString(), date, false));
    }
    final remainingDays = 42 - dayWidgets.length;
    for (int i = 1; i <= remainingDays; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month + 1, i);
      dayWidgets.add(_buildDayWidget(i.toString(), date, true));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      children: dayWidgets,
    );
  }

  Widget _buildDayWidget(String text, DateTime date, bool isOutsideMonth) {
    final isSelected = _isSelected(date);

    return GestureDetector(
      onTap: () => _selectDate(date),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? CustomColors.background : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? Colors.black // Use black for selected dates
                  : (isOutsideMonth
                  ? Colors.white30
                  : CustomColors.background),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}