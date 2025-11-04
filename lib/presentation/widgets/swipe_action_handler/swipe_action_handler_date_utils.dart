import '../../../data/models/task.dart';

/// 滑动动作处理器的日期工具方法
class SwipeActionHandlerDateUtils {
  /// 根据任务当前状态计算下一个合适的推迟日期
  static DateTime getNextScheduledDate(DateTime? currentDueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final thisWeekSaturday = getThisWeekSaturday(today);
    final thisMonthEnd = getEndOfMonth(today);
    
    // 如果没有当前日期，默认为今天
    final dueDate = currentDueDate ?? today;
    final normalizedDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    // 获取下一个可用的日期选项
    final nextDates = [tomorrow, thisWeekSaturday, thisMonthEnd];
    
    // 找到第一个比当前日期晚的日期
    for (final nextDate in nextDates) {
      if (nextDate.isAfter(normalizedDueDate)) {
        return nextDate;
      }
    }
    
    // 如果都更早，则推迟到下个月
    return DateTime(today.year, today.month + 1, 1);
  }

  /// 根据日期确定任务分区
  static TaskSection sectionForDate(DateTime date) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final difference = normalizedDate.difference(normalizedNow).inDays;
    if (difference <= 0) {
      return TaskSection.today;
    }
    if (difference == 1) {
      return TaskSection.tomorrow;
    }
    return TaskSection.later;
  }

  /// 计算本周六的日期
  /// 如果今天是周六，则返回下周六
  static DateTime getThisWeekSaturday(DateTime now) {
    final daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  /// 计算本月最后一天的日期
  static DateTime getEndOfMonth(DateTime now) {
    return DateTime(now.year, now.month + 1, 0);
  }

  /// 格式化日期用于显示
  static String formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (normalizedDate == today) {
      return 'today';
    } else if (normalizedDate == tomorrow) {
      return 'tomorrow';
    } else {
      // 使用简单的日期格式
      return '${date.month}/${date.day}';
    }
  }
}

