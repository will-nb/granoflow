import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';

class InboxQuickDatePicker extends StatelessWidget {
  const InboxQuickDatePicker({
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
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(l10n.datePickerTitle, style: theme.textTheme.titleMedium),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Divider(height: 1),
          _QuickDateTile(
            icon: Icons.calendar_today,
            label: l10n.datePickerToday,
            onTap: () => Navigator.of(context).pop(today),
          ),
          _QuickDateTile(
            icon: Icons.calendar_today,
            label: l10n.datePickerTomorrow,
            onTap: () => Navigator.of(context).pop(tomorrow),
          ),
          _QuickDateTile(
            icon: Icons.calendar_today,
            label: l10n.datePickerThisWeek,
            onTap: () => Navigator.of(context).pop(thisWeek),
          ),
          _QuickDateTile(
            icon: Icons.calendar_today,
            label: l10n.datePickerThisMonth,
            onTap: () => Navigator.of(context).pop(thisMonth),
          ),
          const Divider(height: 1),
          _QuickDateTile(
            icon: Icons.calendar_month,
            label: l10n.datePickerCustom,
            onTap: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }
}

class _QuickDateTile extends StatelessWidget {
  const _QuickDateTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}

