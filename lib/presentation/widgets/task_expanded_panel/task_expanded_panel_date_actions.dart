import 'package:flutter/material.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 选择任务日期
Future<void> selectTaskDate(
  BuildContext context,
  Task task,
  String localeName,
  ValueChanged<DateTime?>? onDateChanged,
) async {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // 显示快速选择对话框
  final quickSelection = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          leading: const Icon(Icons.today),
          title: Text(l10n.datePickerToday),
          onTap: () => Navigator.pop(context, 'today'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(l10n.datePickerTomorrow),
          onTap: () => Navigator.pop(context, 'tomorrow'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_view_week),
          title: Text(l10n.datePickerThisWeek),
          onTap: () => Navigator.pop(context, 'thisWeek'),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: Text(l10n.datePickerThisMonth),
          onTap: () => Navigator.pop(context, 'thisMonth'),
        ),
        ListTile(
          leading: const Icon(Icons.event),
          title: Text(l10n.datePickerCustom),
          onTap: () => Navigator.pop(context, 'custom'),
        ),
      ],
    ),
  );

  if (quickSelection == null || !context.mounted) return;

  DateTime? selectedDate;

  switch (quickSelection) {
    case 'today':
      selectedDate = today;
      break;
    case 'tomorrow':
      selectedDate = today.add(const Duration(days: 1));
      break;
    case 'thisWeek':
      selectedDate = _getThisWeekSaturday(today);
      break;
    case 'thisMonth':
      selectedDate = _getEndOfMonth(today);
      break;
    case 'custom':
      selectedDate = await showDatePicker(
        context: context,
        initialDate: task.dueAt ?? today,
        firstDate: today,
        lastDate: today.add(const Duration(days: 365 * 2)),
      );
      break;
  }

  if (selectedDate != null && context.mounted) {
    onDateChanged?.call(selectedDate);
  }
}

/// 计算本周六的日期
/// 如果今天是周六，则返回下周六
DateTime _getThisWeekSaturday(DateTime now) {
  final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
  return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
}

/// 计算本月最后一天的日期
DateTime _getEndOfMonth(DateTime now) {
  return DateTime(now.year, now.month + 1, 0);
}

