/// 任务区域边界计算工具类
/// 
/// 统一管理任务区域（TaskSection）的边界计算逻辑，
/// 避免在不同模块（TaskService、TaskRepository、SortIndexService等）中重复实现。
/// 
/// ⚠️ 定稿，不可修改
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
  /// - < next week start (Monday) → thisWeek
  /// - < next month start → thisMonth
  /// - >= next month start → later
  static TaskSection getSectionForDate(DateTime? dueAt, {DateTime? now}) {
    if (dueAt == null) {
      return TaskSection.later;
    }

    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final tomorrow = DateTime(currentTime.year, currentTime.month, currentTime.day + 1);
    final weekStart = _getThisWeekStart(currentTime);
    final nextWeekStart = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);
    final nextMonthStart = DateTime(currentTime.year, currentTime.month + 1, 1);

    final dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);

    if (dueDate.isBefore(today)) {
      return TaskSection.overdue;
    } else if (dueDate.isAtSameMomentAs(today)) {
      return TaskSection.today;
    } else if (dueDate.isAtSameMomentAs(tomorrow)) {
      return TaskSection.tomorrow;
    } else if (dueDate.isBefore(nextWeekStart)) {
      return TaskSection.thisWeek;
    } else if (dueDate.isBefore(nextMonthStart)) {
      return TaskSection.thisMonth;
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
        // 本周：本周一 23:59:59
        final weekStart = _getThisWeekStart(currentTime);
        return DateTime(weekStart.year, weekStart.month, weekStart.day, 23, 59, 59);
      case TaskSection.thisMonth:
        // 本月：当月第一天 23:59:59
        return DateTime(currentTime.year, currentTime.month, 1, 23, 59, 59);
      case TaskSection.later:
        // 以后：下月第一天 23:59:59
        final nextMonth = DateTime(currentTime.year, currentTime.month + 1, 1);
        return DateTime(nextMonth.year, nextMonth.month, nextMonth.day, 23, 59, 59);
      default:
        return currentTime;
    }
  }

  /// 获取本周开始时间（周一 00:00:00）
  static DateTime _getThisWeekStart(DateTime now) {
    final daysFromMonday = (now.weekday - DateTime.monday) % 7;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }
}

