import '../../../data/models/task.dart';

/// 任务分区日期规则工具
class TaskSectionDateRules {
  TaskSectionDateRules._();

  /// 计算分区的起始日期（本地时间，00:00:00）
  static DateTime startOfSection(TaskSection section, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    switch (section) {
      case TaskSection.overdue:
        return DateTime(today.year, today.month, today.day - 1);
      case TaskSection.today:
        return today;
      case TaskSection.tomorrow:
        return DateTime(today.year, today.month, today.day + 1);
      case TaskSection.thisWeek:
        final weekStart = _startOfWeek(current);
        final base = DateTime(weekStart.year, weekStart.month, weekStart.day);
        return base.isBefore(today) ? today : base;
      case TaskSection.thisMonth:
        final firstDay = DateTime(today.year, today.month, 1);
        return firstDay.isBefore(today) ? today : firstDay;
      case TaskSection.nextMonth:
        final nextMonth = DateTime(today.year, today.month + 1, 1);
        return DateTime(nextMonth.year, nextMonth.month, nextMonth.day);
      case TaskSection.later:
        final nextNextMonth = DateTime(today.year, today.month + 2, 1);
        return DateTime(nextNextMonth.year, nextNextMonth.month, nextNextMonth.day);
      case TaskSection.completed:
      case TaskSection.archived:
      case TaskSection.trash:
        return today;
    }
  }

  /// 当缺乏邻居任务的截止日期时，使用分区默认日期
  static DateTime fallbackDueDate(TaskSection section, {DateTime? now}) {
    // 规则 A：区域顶部使用起始日期
    return startOfSection(section, now: now);
  }

  /// 根据前后邻居任务决定新的 dueDate
  ///
  /// - 优先复制 [anchorDue]
  /// - 若 anchor 为空，则使用分区默认日期
  static DateTime resolveDueDateFromAnchor(
    TaskSection section,
    DateTime? anchorDue, {
    DateTime? now,
  }) {
    if (anchorDue != null) {
      return anchorDue;
    }
    return fallbackDueDate(section, now: now);
  }

  static DateTime _startOfWeek(DateTime now) {
    final daysFromMonday = (now.weekday - DateTime.monday) % 7;
    final monday = now.subtract(Duration(days: daysFromMonday));
    return DateTime(monday.year, monday.month, monday.day);
  }
}
