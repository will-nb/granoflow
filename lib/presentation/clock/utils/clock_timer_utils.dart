import 'dart:math' as math;

/// 计时器工具函数
/// 
/// 提供时间格式化、超时计算、实际运行时间计算等功能
class ClockTimerUtils {
  const ClockTimerUtils._();

  /// 格式化正向计时时间为 HH:MM:SS 格式
  /// 
  /// 例如：Duration(hours: 1, minutes: 23, seconds: 45) -> "01:23:45"
  static String formatElapsedTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:'
           '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化倒计时时间为 MM:SS 格式
  /// 
  /// 如果时间为负数，会显示负号
  /// 例如：
  /// - Duration(minutes: 5, seconds: 30) -> "05:30"
  /// - Duration(minutes: -5, seconds: -30) -> "-05:30"
  static String formatCountdown(Duration duration) {
    final isNegative = duration.isNegative;
    final absDuration = duration.abs();
    final minutes = absDuration.inMinutes;
    final seconds = absDuration.inSeconds.remainder(60);
    
    final sign = isNegative ? '-' : '';
    return '$sign${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }

  /// 计算超时百分比
  /// 
  /// 超时百分比 = |超时秒数| / 原始时长
  /// 返回值范围：0.0 - 1.0
  /// 
  /// 例如：超时 5 分钟，原始 25 分钟，返回 0.2
  static double calculateOvertimePercentage({
    required int overtimeSeconds,
    required int originalDurationSeconds,
  }) {
    if (originalDurationSeconds <= 0) {
      return 0.0;
    }
    final absOvertime = overtimeSeconds.abs();
    final percentage = absOvertime / originalDurationSeconds;
    return math.min(percentage, 1.0);
  }

  /// 计算实际运行时间（排除暂停时间）
  /// 
  /// [startTime] 开始时间
  /// [endTime] 结束时间（如果为 null，使用当前时间）
  /// [pausePeriods] 暂停时间段列表，每个元素是一个包含开始和结束时间的元组
  /// 
  /// 返回实际运行时间（不包含暂停时间）
  static Duration calculateActualRunningTime({
    required DateTime startTime,
    DateTime? endTime,
    required List<({DateTime start, DateTime end})> pausePeriods,
  }) {
    final actualEnd = endTime ?? DateTime.now();
    final totalDuration = actualEnd.difference(startTime);
    
    // 计算所有暂停时间的总和
    final pauseDuration = pausePeriods.fold<Duration>(
      Duration.zero,
      (sum, period) {
        final pauseTime = period.end.difference(period.start);
        return sum + pauseTime;
      },
    );
    
    // 实际运行时间 = 总时间 - 暂停时间
    final actualRunningTime = totalDuration - pauseDuration;
    
    // 确保不会返回负数
    return actualRunningTime.isNegative ? Duration.zero : actualRunningTime;
  }
}

