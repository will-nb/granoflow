import 'package:flutter/material.dart';

import '../../../core/theme/app_calendar_tokens.dart';

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
    this.availableHeight,
  });

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? Function(DateTime) getSpecialLabel;
  final double? availableHeight;

  @override
  Widget build(BuildContext context) {
    final calendarTokens = context.calendarTokens;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // 计算可用宽度（减去 padding 和 spacing）
        final horizontalPadding = calendarTokens.cellHorizontalPadding * 2;
        final spacing = calendarTokens.cellSpacing * 6; // 7列，6个间距
        final availableWidth = constraints.maxWidth - horizontalPadding - spacing;

        // 计算单元格宽度（7列）
        final cellWidth = availableWidth / 7;

        // 计算需要的行数
        final totalCells = days.length;
        final rows = (totalCells / 7).ceil();

        // 计算单元格高度
        double cellHeight;
        double aspectRatio;

        if (availableHeight != null && availableHeight!.isFinite && availableHeight! > 0) {
          // 有高度限制，根据可用高度动态计算
          final verticalSpacing = calendarTokens.cellSpacing * (rows - 1);
          final availableCellHeight = (availableHeight! - verticalSpacing) / rows;
          // 在最小/最大高度范围内调整
          cellHeight = availableCellHeight.clamp(
            calendarTokens.cellMinHeight,
            calendarTokens.cellMaxHeight,
          );
        } else {
          // 没有高度限制，使用默认比例
          cellHeight = cellWidth / calendarTokens.cellDefaultAspectRatio;
        }

        // 计算实际的 aspect ratio
        aspectRatio = cellWidth / cellHeight;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: calendarTokens.cellHorizontalPadding),
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: calendarTokens.cellSpacing,
            crossAxisSpacing: calendarTokens.cellSpacing,
            childAspectRatio: aspectRatio,
            children: days,
          ),
        );
      },
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
    
    // 如果有特殊标签，优先显示标签，不显示数字
    final showLabelOnly = specialLabel != null;

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
            if (showLabelOnly)
              // 只显示标签，文字使用 labelMedium 样式（从主题获取）
              Text(
                specialLabel!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else
              // 显示日期数字
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
          ],
        ),
      ),
    );
  }
}

