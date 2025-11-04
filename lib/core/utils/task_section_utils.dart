/// 任务区域边界计算工具类
/// 
/// 统一管理任务区域（TaskSection）的边界计算逻辑，
/// 避免在不同模块（TaskService、TaskRepository、SortIndexService等）中重复实现。
/// 
/// 边界定义（严禁修改）：
/// - 已逾期：[~, <今天00:00:00)
/// - 今天：[>=今天00:00:00, <明天00:00:00)
/// - 明天：[>=明天00:00:00, <后天00:00:00)
/// - 本周：[>=后天00:00:00, <下周日00:00:00) （如果今天是周六，则为空范围）
/// - 当月：[>=下周日00:00:00, <下月1日00:00:00) （如果本周跨月，则为空范围）
/// - 下月：[>=下月1日00:00:00, <下下月1日00:00:00)
/// - 以后：[>=下下月1日00:00:00, ~)
/// 
/// 注意：一周以周日为第一天，与日历显示保持一致（一排一周）。
/// 
/// 定稿，不可修改
/// 该文件包含核心的任务分区逻辑，任何修改都可能影响任务显示、排序、拖拽等功能。
/// 如需修改，必须同步更新所有使用此类的地方，并进行完整测试。

import '../../data/models/task.dart';

/// 任务区域边界计算工具类
class TaskSectionUtils {
  TaskSectionUtils._();

  /// 根据任务的 dueAt 获取其所属区域
  /// 
  /// 逻辑：
  /// - null → later
  /// - < today → overdue
  /// - == today → today
  /// - == tomorrow → tomorrow
  /// - < next week start (Sunday) → thisWeek
  /// - < next month start → thisMonth
  /// - < next next month start → nextMonth
  /// - >= next next month start → later
  static TaskSection getSectionForDate(DateTime? dueAt, {DateTime? now}) {
    if (dueAt == null) {
      return TaskSection.later;
    }

    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final tomorrow = DateTime(currentTime.year, currentTime.month, currentTime.day + 1);
    final dayAfterTomorrow = DateTime(currentTime.year, currentTime.month, currentTime.day + 2);
    final weekStart = _getThisWeekStart(currentTime);
    final nextWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
    final nextMonthStart = DateTime(currentTime.year, currentTime.month + 1, 1);
    final nextNextMonthStart = DateTime(currentTime.year, currentTime.month + 2, 1);

    final dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);

    if (dueDate.isBefore(today)) {
      return TaskSection.overdue;
    } else if (dueDate.isAtSameMomentAs(today)) {
      return TaskSection.today;
    } else if (dueDate.isAtSameMomentAs(tomorrow)) {
      return TaskSection.tomorrow;
    } else if (dueDate.isBefore(nextWeekStart)) {
      // 本周：从后天开始到下周日之前（如果今天是周六，则本周为空范围）
      if (dayAfterTomorrow.isBefore(nextWeekStart)) {
        return TaskSection.thisWeek;
      } else {
        // 今天是周六，本周为空范围，直接进入当月或以后
        if (dueDate.isBefore(nextMonthStart)) {
          return TaskSection.thisMonth;
        } else if (dueDate.isBefore(nextNextMonthStart)) {
          return TaskSection.nextMonth;
        } else {
          return TaskSection.later;
        }
      }
    } else if (dueDate.isBefore(nextMonthStart)) {
      return TaskSection.thisMonth;
    } else if (dueDate.isBefore(nextNextMonthStart)) {
      return TaskSection.nextMonth;
    } else {
      return TaskSection.later;
    }
  }

  /// 获取区域的结束时间点（第一天的 23:59:59）
  /// 
  /// 用于跨区域拖拽时更新任务的 dueAt
  static DateTime getSectionEndTime(TaskSection section, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    
    switch (section) {
      case TaskSection.overdue:
        // 已逾期：昨天 23:59:59
        return DateTime(currentTime.year, currentTime.month, currentTime.day - 1, 23, 59, 59);
      case TaskSection.today:
        // 今日：今天 23:59:59
        return DateTime(currentTime.year, currentTime.month, currentTime.day, 23, 59, 59);
      case TaskSection.tomorrow:
        // 明日：明天 23:59:59
        return DateTime(currentTime.year, currentTime.month, currentTime.day + 1, 23, 59, 59);
      case TaskSection.thisWeek:
        // 本周：本周六 23:59:59（下周日 00:00:00 之前）
        final weekStart = _getThisWeekStart(currentTime);
        final saturday = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
        return DateTime(saturday.year, saturday.month, saturday.day, 23, 59, 59);
      case TaskSection.thisMonth:
        // 本月：当月最后一天 23:59:59（下月1日 00:00:00 之前）
        final lastDayOfMonth = DateTime(currentTime.year, currentTime.month + 1, 0);
        return DateTime(lastDayOfMonth.year, lastDayOfMonth.month, lastDayOfMonth.day, 23, 59, 59);
      case TaskSection.nextMonth:
        // 下月：下月最后一天 23:59:59（下下月1日 00:00:00 之前）
        final lastDayOfNextMonth = DateTime(currentTime.year, currentTime.month + 2, 0);
        return DateTime(lastDayOfNextMonth.year, lastDayOfNextMonth.month, lastDayOfNextMonth.day, 23, 59, 59);
      case TaskSection.later:
        // 以后：下下月第一天 23:59:59（作为默认值）
        final nextNextMonth = DateTime(currentTime.year, currentTime.month + 2, 1);
        return DateTime(nextNextMonth.year, nextNextMonth.month, nextNextMonth.day, 23, 59, 59);
      default:
        return currentTime;
    }
  }

  /// 获取区域的开始时间（00:00:00）
  /// 
  /// 用于数据库查询，返回区域的开始边界时间点
  static DateTime getSectionStartTime(TaskSection section, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    
    switch (section) {
      case TaskSection.overdue:
        // 已逾期：负无穷（实际使用时用 null 或极小值）
        return DateTime(1970, 1, 1);
      case TaskSection.today:
        // 今天：今天 00:00:00
        return today;
      case TaskSection.tomorrow:
        // 明天：明天 00:00:00
        return DateTime(currentTime.year, currentTime.month, currentTime.day + 1);
      case TaskSection.thisWeek:
        // 本周：后天 00:00:00（如果今天是周六，则本周为空范围）
        return DateTime(currentTime.year, currentTime.month, currentTime.day + 2);
      case TaskSection.thisMonth:
        // 当月：下周日 00:00:00
        final weekStart = _getThisWeekStart(currentTime);
        return DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
      case TaskSection.nextMonth:
        // 下月：下月1日 00:00:00
        return DateTime(currentTime.year, currentTime.month + 1, 1);
      case TaskSection.later:
        // 以后：下下月1日 00:00:00
        return DateTime(currentTime.year, currentTime.month + 2, 1);
      default:
        return today;
    }
  }

  /// 获取区域的结束时间（下一区域的开始时间，00:00:00，不包含）
  /// 
  /// 用于数据库查询，返回区域的结束边界时间点（不包含）
  /// 配合 dueAtBetween(start, end, includeUpper: false) 使用
  static DateTime getSectionEndTimeForQuery(TaskSection section, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    
    switch (section) {
      case TaskSection.overdue:
        // 已逾期：今天 00:00:00（不包含）
        return today;
      case TaskSection.today:
        // 今天：明天 00:00:00（不包含）
        return DateTime(currentTime.year, currentTime.month, currentTime.day + 1);
      case TaskSection.tomorrow:
        // 明天：后天 00:00:00（不包含）
        return DateTime(currentTime.year, currentTime.month, currentTime.day + 2);
      case TaskSection.thisWeek:
        // 本周：下周日 00:00:00（不包含）
        final weekStart = _getThisWeekStart(currentTime);
        return DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
      case TaskSection.thisMonth:
        // 当月：下月1日 00:00:00（不包含）
        return DateTime(currentTime.year, currentTime.month + 1, 1);
      case TaskSection.nextMonth:
        // 下月：下下月1日 00:00:00（不包含）
        return DateTime(currentTime.year, currentTime.month + 2, 1);
      case TaskSection.later:
        // 以后：正无穷（实际使用时用极大值）
        return DateTime(2100, 1, 1);
      default:
        return today;
    }
  }

  /// 获取本周开始时间（周日 00:00:00）
  /// 
  /// 一周以周日为第一天，与日历显示保持一致
  static DateTime _getThisWeekStart(DateTime now) {
    final daysFromSunday = now.weekday % 7; // 0=Sunday, 1=Monday, ..., 6=Saturday
    return DateTime(now.year, now.month, now.day - daysFromSunday);
  }
}

