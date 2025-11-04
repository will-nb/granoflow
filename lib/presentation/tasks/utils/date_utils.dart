import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../../../data/models/task.dart';

/// Returns the default due date for a given task section.
DateTime defaultDueDate(TaskSection section) {
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day);
  switch (section) {
    case TaskSection.overdue:
      return base.subtract(const Duration(days: 1));
    case TaskSection.today:
      return base;
    case TaskSection.tomorrow:
      return base.add(const Duration(days: 1));
    case TaskSection.thisWeek:
      return base.add(const Duration(days: 2));
    case TaskSection.thisMonth:
      return base.add(const Duration(days: 7));
    case TaskSection.nextMonth:
      return DateTime(now.year, now.month + 1, 1);
    case TaskSection.later:
      return base.add(const Duration(days: 30));
    case TaskSection.completed:
    case TaskSection.archived:
    case TaskSection.trash:
      return base;
  }
}

/// Formats a deadline date for display.
/// Returns null if the date is null.
String? formatDeadline(BuildContext context, DateTime? date) {
  if (date == null) return null;
  final locale = AppLocalizations.of(context).localeName;
  final formatter = DateFormat.yMMMd(locale);
  return formatter.format(date);
}

