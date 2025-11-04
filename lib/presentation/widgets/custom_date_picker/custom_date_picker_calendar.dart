import 'package:flutter/material.dart';

/// 日历网格组件
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    required this.getSpecialLabel,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? Function(DateTime) getSpecialLabel;

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(displayedMonth.year, displayedMonth.month, 1);
    final weekdayOfFirstDay = firstDayOfMonth.weekday % 7; // 0=Sunday, 1=Monday, ...

    final days = <Widget>[];

    // 添加空白占位符
    for (int i = 0; i < weekdayOfFirstDay; i++) {
      days.add(const SizedBox());
    }

    // 添加日期
    for (int day = 1; day <= daysInMonth; day++) {
      final date =
          DateTime(displayedMonth.year, displayedMonth.month, day);
      final isSelected = date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day;
      final isEnabled =
          !date.isBefore(firstDate) && !date.isAfter(lastDate);
      final specialLabel = getSpecialLabel(date);
      final today = DateTime.now();
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      days.add(DayCell(
        day: day,
        isSelected: isSelected,
        isEnabled: isEnabled,
        isToday: isToday,
        specialLabel: specialLabel,
        onTap: isEnabled ? () => onDateSelected(date) : null,
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 0.85,
        children: days,
      ),
    );
  }
}

/// 日期单元格组件
class DayCell extends StatelessWidget {
  const DayCell({
    super.key,
    required this.day,
    required this.isSelected,
    required this.isEnabled,
    required this.isToday,
    this.specialLabel,
    this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isEnabled;
  final bool isToday;
  final String? specialLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : isToday
                  ? theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.3)
                  : null,
          borderRadius: BorderRadius.circular(20),
          border: isToday && !isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 1)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : isEnabled
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface
                            .withValues(alpha: 0.38),
                fontWeight:
                    isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (specialLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                specialLabel!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                      : theme.colorScheme.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

