import 'package:flutter/material.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/custom_date_picker.dart';

/// 导出日期范围选择对话框
class ExportDateRangeDialog extends StatefulWidget {
  const ExportDateRangeDialog({super.key});

  @override
  State<ExportDateRangeDialog> createState() => _ExportDateRangeDialogState();
}

class _ExportDateRangeDialogState extends State<ExportDateRangeDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _startDate = today;
    _endDate = today;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return AlertDialog(
      title: Text(l10n.calendarReviewExportDateRange),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 快捷选项
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickOptionButton(
                  label: l10n.calendarReviewExportToday,
                  onTap: () {
                    setState(() {
                      _startDate = today;
                      _endDate = today;
                    });
                  },
                ),
                _QuickOptionButton(
                  label: l10n.calendarReviewExportThisWeek,
                  onTap: () {
                    final weekStart = _getWeekStart(today);
                    final weekEnd = _getWeekEnd(today);
                    setState(() {
                      _startDate = weekStart;
                      _endDate = weekEnd;
                    });
                  },
                ),
                _QuickOptionButton(
                  label: l10n.calendarReviewExportThisMonth,
                  onTap: () {
                    final monthStart = DateTime(today.year, today.month, 1);
                    final monthEnd = DateTime(today.year, today.month + 1, 0);
                    setState(() {
                      _startDate = monthStart;
                      _endDate = monthEnd;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 开始日期
            ListTile(
              title: Text(l10n.calendarReviewSelectStartDate),
              subtitle: Text(
                _startDate != null
                    ? CalendarReviewUtils.formatDateShort(_startDate!)
                    : '-',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showCustomDatePicker(
                  context: context,
                  initialDate: _startDate ?? today,
                  firstDate: DateTime(2020, 1, 1),
                  lastDate: today,
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                    if (_endDate != null && _endDate!.isBefore(picked)) {
                      _endDate = picked;
                    }
                  });
                }
              },
            ),
            // 结束日期
            ListTile(
              title: Text(l10n.calendarReviewSelectEndDate),
              subtitle: Text(
                _endDate != null
                    ? CalendarReviewUtils.formatDateShort(_endDate!)
                    : '-',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showCustomDatePicker(
                  context: context,
                  initialDate: _endDate ?? today,
                  firstDate: _startDate ?? DateTime(2020, 1, 1),
                  lastDate: today,
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _startDate != null && _endDate != null
              ? () => Navigator.of(context).pop({
                    'start': _startDate,
                    'end': _endDate,
                  })
              : null,
          child: Text(l10n.commonConfirm),
        ),
      ],
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  DateTime _getWeekEnd(DateTime date) {
    final weekStart = _getWeekStart(date);
    return DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
  }
}

class _QuickOptionButton extends StatelessWidget {
  const _QuickOptionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text(label),
    );
  }
}
