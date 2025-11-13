import 'package:flutter/foundation.dart';

/// 首页统计数据模型
@immutable
class HomeStatistics {
  const HomeStatistics({
    required this.completedCount,
    required this.focusMinutes,
  });

  /// 完成的任务数量
  final int completedCount;

  /// 专注时间（分钟）
  final int focusMinutes;

  HomeStatistics copyWith({
    int? completedCount,
    int? focusMinutes,
  }) {
    return HomeStatistics(
      completedCount: completedCount ?? this.completedCount,
      focusMinutes: focusMinutes ?? this.focusMinutes,
    );
  }

  @override
  String toString() {
    return 'HomeStatistics(completedCount: $completedCount, focusMinutes: $focusMinutes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeStatistics &&
        other.completedCount == completedCount &&
        other.focusMinutes == focusMinutes;
  }

  @override
  int get hashCode => completedCount.hashCode ^ focusMinutes.hashCode;
}

/// 最佳日期统计数据模型
@immutable
class TopDateStatistics {
  const TopDateStatistics({
    required this.date,
    this.completedCount,
    this.focusMinutes,
  }) : assert(
          completedCount != null || focusMinutes != null,
          'Either completedCount or focusMinutes must be provided',
        );

  /// 日期（只包含年月日）
  final DateTime date;

  /// 完成的任务数量（可选）
  final int? completedCount;

  /// 专注时间（分钟）（可选）
  final int? focusMinutes;

  TopDateStatistics copyWith({
    DateTime? date,
    int? completedCount,
    int? focusMinutes,
  }) {
    return TopDateStatistics(
      date: date ?? this.date,
      completedCount: completedCount ?? this.completedCount,
      focusMinutes: focusMinutes ?? this.focusMinutes,
    );
  }

  @override
  String toString() {
    if (completedCount != null) {
      return 'TopDateStatistics(date: $date, completedCount: $completedCount)';
    } else {
      return 'TopDateStatistics(date: $date, focusMinutes: $focusMinutes)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TopDateStatistics &&
        other.date == date &&
        other.completedCount == completedCount &&
        other.focusMinutes == focusMinutes;
  }

  @override
  int get hashCode => date.hashCode ^ completedCount.hashCode ^ focusMinutes.hashCode;
}

/// 所有统计数据的组合模型
@immutable
class AllStatistics {
  const AllStatistics({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
    this.thisMonthTopCompletedDate,
    this.thisMonthTopFocusDate,
    this.totalTopCompletedDate,
    this.totalTopFocusDate,
  });

  /// 今天的统计数据
  final HomeStatistics today;

  /// 本周的统计数据
  final HomeStatistics thisWeek;

  /// 当月的统计数据
  final HomeStatistics thisMonth;

  /// 全部的统计数据（所有历史数据）
  final HomeStatistics total;

  /// 当月最佳完成日（可为 null）
  final TopDateStatistics? thisMonthTopCompletedDate;

  /// 当月最佳专注日（可为 null）
  final TopDateStatistics? thisMonthTopFocusDate;

  /// 历史最佳完成日（可为 null）
  final TopDateStatistics? totalTopCompletedDate;

  /// 历史最佳专注日（可为 null）
  final TopDateStatistics? totalTopFocusDate;

  AllStatistics copyWith({
    HomeStatistics? today,
    HomeStatistics? thisWeek,
    HomeStatistics? thisMonth,
    HomeStatistics? total,
    TopDateStatistics? thisMonthTopCompletedDate,
    TopDateStatistics? thisMonthTopFocusDate,
    TopDateStatistics? totalTopCompletedDate,
    TopDateStatistics? totalTopFocusDate,
  }) {
    return AllStatistics(
      today: today ?? this.today,
      thisWeek: thisWeek ?? this.thisWeek,
      thisMonth: thisMonth ?? this.thisMonth,
      total: total ?? this.total,
      thisMonthTopCompletedDate: thisMonthTopCompletedDate ?? this.thisMonthTopCompletedDate,
      thisMonthTopFocusDate: thisMonthTopFocusDate ?? this.thisMonthTopFocusDate,
      totalTopCompletedDate: totalTopCompletedDate ?? this.totalTopCompletedDate,
      totalTopFocusDate: totalTopFocusDate ?? this.totalTopFocusDate,
    );
  }

  @override
  String toString() {
    return 'AllStatistics(today: $today, thisWeek: $thisWeek, thisMonth: $thisMonth, total: $total, thisMonthTopCompletedDate: $thisMonthTopCompletedDate, thisMonthTopFocusDate: $thisMonthTopFocusDate, totalTopCompletedDate: $totalTopCompletedDate, totalTopFocusDate: $totalTopFocusDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllStatistics &&
        other.today == today &&
        other.thisWeek == thisWeek &&
        other.thisMonth == thisMonth &&
        other.total == total &&
        other.thisMonthTopCompletedDate == thisMonthTopCompletedDate &&
        other.thisMonthTopFocusDate == thisMonthTopFocusDate &&
        other.totalTopCompletedDate == totalTopCompletedDate &&
        other.totalTopFocusDate == totalTopFocusDate;
  }

  @override
  int get hashCode =>
      today.hashCode ^
      thisWeek.hashCode ^
      thisMonth.hashCode ^
      total.hashCode ^
      thisMonthTopCompletedDate.hashCode ^
      thisMonthTopFocusDate.hashCode ^
      totalTopCompletedDate.hashCode ^
      totalTopFocusDate.hashCode;
}

