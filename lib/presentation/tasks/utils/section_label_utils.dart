import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../../../data/models/task.dart';

/// Returns the localized label for a given task section.
String labelForSection(AppLocalizations l10n, TaskSection section) {
  switch (section) {
    case TaskSection.overdue:
      return l10n.plannerSectionOverdueTitle;
    case TaskSection.today:
      return l10n.plannerSectionTodayTitle;
    case TaskSection.tomorrow:
      return l10n.plannerSectionTomorrowTitle;
    case TaskSection.thisWeek:
      return l10n.plannerSectionThisWeekTitle;
    case TaskSection.thisMonth:
      return l10n.plannerSectionThisMonthTitle;
    case TaskSection.nextMonth:
      return l10n.plannerSectionNextMonthTitle;
    case TaskSection.later:
      return l10n.plannerSectionLaterTitle;
    case TaskSection.completed:
      return l10n.navCompletedTitle;
    case TaskSection.archived:
      return l10n.navArchivedTitle;
    case TaskSection.trash:
      return l10n.navTrashTitle;
  }
}

