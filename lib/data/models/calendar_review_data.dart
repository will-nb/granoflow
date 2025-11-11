import 'package:flutter/foundation.dart';

import 'focus_session.dart';
import 'task.dart';

/// 每日统计数据
@immutable
class DayReviewData {
  const DayReviewData({
    required this.date,
    required this.focusMinutes,
    required this.completedTaskCount,
    required this.sessionCount,
  });

  final DateTime date;
  final int focusMinutes;
  final int completedTaskCount;
  final int sessionCount;

  DayReviewData copyWith({
    DateTime? date,
    int? focusMinutes,
    int? completedTaskCount,
    int? sessionCount,
  }) {
    return DayReviewData(
      date: date ?? this.date,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}

/// 指定日期的详细数据
@immutable
class DayDetailData {
  const DayDetailData({
    required this.date,
    required this.focusMinutes,
    required this.completedTasks,
    required this.sessions,
  });

  final DateTime date;
  final int focusMinutes;
  final List<Task> completedTasks;
  final List<FocusSession> sessions;

  DayDetailData copyWith({
    DateTime? date,
    int? focusMinutes,
    List<Task>? completedTasks,
    List<FocusSession>? sessions,
  }) {
    return DayDetailData(
      date: date ?? this.date,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      completedTasks: completedTasks ?? this.completedTasks,
      sessions: sessions ?? this.sessions,
    );
  }
}

/// 筛选条件
@immutable
class CalendarFilter {
  const CalendarFilter({
    this.projectId,
    this.tags = const <String>[],
  });

  final String? projectId;
  final List<String> tags;

  bool get isEmpty => projectId == null && tags.isEmpty;

  CalendarFilter copyWith({
    String? projectId,
    List<String>? tags,
  }) {
    return CalendarFilter(
      projectId: projectId ?? this.projectId,
      tags: tags ?? this.tags,
    );
  }
}

/// 周统计数据
@immutable
class WeekReviewData {
  const WeekReviewData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalFocusMinutes,
    required this.completedTaskCount,
    required this.averageDailyMinutes,
    required this.sessionCount,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalFocusMinutes;
  final int completedTaskCount;
  final int averageDailyMinutes;
  final int sessionCount;

  WeekReviewData copyWith({
    DateTime? weekStart,
    DateTime? weekEnd,
    int? totalFocusMinutes,
    int? completedTaskCount,
    int? averageDailyMinutes,
    int? sessionCount,
  }) {
    return WeekReviewData(
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      averageDailyMinutes: averageDailyMinutes ?? this.averageDailyMinutes,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }
}

/// 月统计数据
@immutable
class MonthReviewData {
  const MonthReviewData({
    required this.year,
    required this.month,
    required this.totalFocusMinutes,
    required this.completedTaskCount,
    required this.averageDailyMinutes,
    required this.mostActiveDate,
  });

  final int year;
  final int month;
  final int totalFocusMinutes;
  final int completedTaskCount;
  final int averageDailyMinutes;
  final DateTime? mostActiveDate;

  MonthReviewData copyWith({
    int? year,
    int? month,
    int? totalFocusMinutes,
    int? completedTaskCount,
    int? averageDailyMinutes,
    DateTime? mostActiveDate,
  }) {
    return MonthReviewData(
      year: year ?? this.year,
      month: month ?? this.month,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      averageDailyMinutes: averageDailyMinutes ?? this.averageDailyMinutes,
      mostActiveDate: mostActiveDate ?? this.mostActiveDate,
    );
  }
}
