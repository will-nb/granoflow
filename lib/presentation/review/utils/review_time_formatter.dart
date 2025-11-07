/// 回顾页面时间格式化工具
class ReviewTimeFormatter {
  /// 人性化显示分钟数
  /// 如果小于60分钟，显示为 "X分钟"
  /// 如果大于等于60分钟，显示为 "X小时Y分钟"
  static String formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes分钟';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) {
      return '$hours小时';
    }

    return '$hours小时$remainingMinutes分钟';
  }

  /// 格式化为小时（保留1位小数）
  /// 例如：2.5小时
  static String formatHours(double hours) {
    return hours.toStringAsFixed(1);
  }
}

