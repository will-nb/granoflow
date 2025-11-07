import 'package:flutter/foundation.dart';

import 'task.dart';

/// 回顾页面数据模型
/// 包含所有需要显示的数据
@immutable
class ReviewData {
  const ReviewData({
    required this.welcome,
    required this.stats,
    required this.projects,
    required this.standaloneTasks,
    this.longestCompletedTask,
    this.longestArchivedTask,
    this.mostCompletedDay,
  });

  /// 欢迎信息
  final ReviewWelcomeData welcome;

  /// 统计信息
  final ReviewStatsData stats;

  /// 活跃项目列表
  final List<ReviewProjectInfo> projects;

  /// 独立任务统计
  final ReviewStandaloneTasksData standaloneTasks;

  /// 最长已完成任务信息（如果存在）
  final ReviewLongestTaskInfo? longestCompletedTask;

  /// 最长归档任务信息（如果存在）
  final ReviewLongestTaskInfo? longestArchivedTask;

  /// 完成根任务最多的一天（如果存在）
  final ReviewMostCompletedDayInfo? mostCompletedDay;
}

/// 欢迎信息
@immutable
class ReviewWelcomeData {
  const ReviewWelcomeData({
    required this.dayCount,
  });

  /// 用户使用 app 的天数
  final int dayCount;
}

/// 统计信息
@immutable
class ReviewStatsData {
  const ReviewStatsData({
    required this.projectCount,
    required this.taskCount,
  });

  /// 项目总数（不包括回收站）
  final int projectCount;

  /// 任务总数（不包括回收站和伪删除，只统计根任务）
  final int taskCount;
}

/// 项目信息
@immutable
class ReviewProjectInfo {
  const ReviewProjectInfo({
    required this.projectId,
    required this.name,
    required this.taskCount,
  });

  /// 项目 ID
  final String projectId;

  /// 项目名称
  final String name;

  /// 该项目包含的任务数量（只统计根任务，不包括回收站）
  final int taskCount;
}

/// 独立任务统计
@immutable
class ReviewStandaloneTasksData {
  const ReviewStandaloneTasksData({
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.archivedCount,
  });

  /// 独立任务总数（不包括回收站和伪删除，只统计根任务）
  final int totalCount;

  /// 正在进行的独立任务数量（pending 或 doing 状态）
  final int activeCount;

  /// 已完成的独立任务数量
  final int completedCount;

  /// 归档的独立任务数量
  final int archivedCount;
}

/// 最长任务信息（已完成或归档）
@immutable
class ReviewLongestTaskInfo {
  const ReviewLongestTaskInfo({
    required this.task,
    required this.totalMinutes,
    required this.subtasks,
  });

  /// 任务对象
  final Task task;

  /// 任务总花费时间（分钟）
  final int totalMinutes;

  /// 子任务列表（如果存在）
  final List<Task> subtasks;
}

/// 完成根任务最多的一天
@immutable
class ReviewMostCompletedDayInfo {
  const ReviewMostCompletedDayInfo({
    required this.date,
    required this.taskCount,
    required this.totalHours,
  });

  /// 日期
  final DateTime date;

  /// 那一天完成的根任务数量
  final int taskCount;

  /// 那一天所有根任务的总花费时间（小时）
  final double totalHours;
}

