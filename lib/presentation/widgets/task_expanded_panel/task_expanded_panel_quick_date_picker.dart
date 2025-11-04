import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 快速日期选择对话框
class QuickDatePicker extends StatelessWidget {
  const QuickDatePicker({
    super.key,
    required this.today,
    required this.tomorrow,
    required this.thisWeek,
    required this.thisMonth,
  });

  final DateTime today;
  final DateTime tomorrow;
  final DateTime thisWeek;
  final DateTime thisMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.datePickerTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          QuickDateOption(
            icon: Icons.today,
            label: l10n.datePickerToday,
            date: today,
            onTap: () => Navigator.pop(context, today),
          ),
          QuickDateOption(
            icon: Icons.calendar_today,
            label: l10n.datePickerTomorrow,
            date: tomorrow,
            onTap: () => Navigator.pop(context, tomorrow),
          ),
          QuickDateOption(
            icon: Icons.calendar_view_week,
            label: l10n.datePickerThisWeek,
            date: thisWeek,
            onTap: () => Navigator.pop(context, thisWeek),
          ),
          QuickDateOption(
            icon: Icons.calendar_month,
            label: l10n.datePickerThisMonth,
            date: thisMonth,
            onTap: () => Navigator.pop(context, thisMonth),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }
}

/// 快速日期选项组件
class QuickDateOption extends StatelessWidget {
  const QuickDateOption({
    super.key,
    required this.icon,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(DateFormat.yMMMd().format(date)),
        onTap: onTap,
      ),
    );
  }
}

