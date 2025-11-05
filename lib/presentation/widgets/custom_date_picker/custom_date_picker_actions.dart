import 'package:flutter/material.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 快捷日期选项按钮组
class QuickDateOptions extends StatelessWidget {
  const QuickDateOptions({
    super.key,
    required this.onDateSelected,
  });

  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final tomorrow = today.add(const Duration(days: 1));
    
    // 本周六
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    final thisSaturday = today.add(
      Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
    );
    
    // 当月最后一天
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthEnd = DateTime(
      lastDayOfMonth.year,
      lastDayOfMonth.month,
      lastDayOfMonth.day,
      23,
      59,
      59,
    );
    
    // 下个月最后一天
    final nextMonthLastDay = DateTime(now.year, now.month + 2, 0);
    final nextMonthEnd = DateTime(
      nextMonthLastDay.year,
      nextMonthLastDay.month,
      nextMonthLastDay.day,
      23,
      59,
      59,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        QuickOptionChip(
          label: l10n.dateToday,
          icon: Icons.today,
          onTap: () => onDateSelected(today),
          color: theme.colorScheme.primary,
        ),
        QuickOptionChip(
          label: l10n.dateTomorrow,
          icon: Icons.wb_sunny_outlined,
          onTap: () => onDateSelected(tomorrow),
          color: theme.colorScheme.primary,
        ),
        QuickOptionChip(
          label: l10n.datePickerThisWeek,
          icon: Icons.event_note,
          onTap: () => onDateSelected(thisSaturday),
          color: theme.colorScheme.primary,
        ),
        QuickOptionChip(
          label: l10n.datePickerMonthEnd,
          icon: Icons.calendar_month,
          onTap: () => onDateSelected(monthEnd),
          color: theme.colorScheme.primary,
        ),
        QuickOptionChip(
          label: l10n.plannerSectionNextMonthTitle,
          icon: Icons.calendar_today,
          onTap: () => onDateSelected(nextMonthEnd),
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

/// 快捷选项芯片
class QuickOptionChip extends StatelessWidget {
  const QuickOptionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

