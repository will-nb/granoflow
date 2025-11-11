/// 日历回顾相关的工具方法
class CalendarReviewUtils {
  CalendarReviewUtils._();

  /// 计算包含指定日期的周的开始日期（周日）
  /// 
  /// 一周以周日为第一天，与 TaskSectionUtils 保持一致
  static DateTime getWeekStart(DateTime date) {
    final daysFromSunday = date.weekday % 7; // 0=Sunday, 1=Monday, ..., 6=Saturday
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  /// 计算包含指定日期的周的结束日期（周六）
  static DateTime getWeekEnd(DateTime date) {
    final weekStart = getWeekStart(date);
    return DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
  }

  /// 计算月的开始日期
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 计算月的结束日期
  static DateTime getMonthEnd(DateTime date) {
    // 下个月的第一天减去一天
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    return DateTime(nextMonth.year, nextMonth.month, nextMonth.day - 1);
  }

  /// 格式化专注时长为小时数（如：2.5h）
  static String formatFocusMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes / 60;
    if (hours == hours.truncateToDouble()) {
      return '${hours.toInt()}h';
    }
    return '${hours.toStringAsFixed(1)}h';
  }
}
