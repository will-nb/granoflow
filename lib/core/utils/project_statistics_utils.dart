import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';

/// 进度统计结果
class ProgressStatistics {
  const ProgressStatistics({
    required this.completedCount,
    required this.totalCount,
    required this.progress,
  });

  /// 已完成任务数
  final int completedCount;

  /// 总任务数
  final int totalCount;

  /// 进度百分比（0.0-1.0）
  final double progress;
}

/// 项目/里程碑进度统计工具类
///
/// 提供统一的进度统计计算方法，确保统计规则一致
class ProjectStatisticsUtils {
  ProjectStatisticsUtils._();

  /// 计算项目进度
  ///
  /// [projectId] 项目ID
  /// [tasks] 项目下的所有任务列表
  ///
  /// 返回进度统计结果
  ///
  /// 统计规则：
  /// - 总任务数包括：pending、doing、paused、completedActive、archived
  /// - 不包括：inbox、trashed、pseudoDeleted
  /// - 已完成任务数包括：completedActive、archived
  static ProgressStatistics calculateProjectProgress(
    String projectId,
    List<Task> tasks,
  ) {
    try {
      // 过滤出属于该项目的任务
      final projectTasks = tasks.where((task) => task.projectId == projectId).toList();

      // 计算总任务数：包括 pending、doing、paused、completedActive、archived
      final totalTasks = projectTasks.where((task) {
        return task.status == TaskStatus.pending ||
            task.status == TaskStatus.doing ||
            task.status == TaskStatus.paused ||
            task.status == TaskStatus.completedActive ||
            task.status == TaskStatus.archived;
      }).toList();

      // 计算已完成任务数：包括 completedActive、archived
      final completedTasks = totalTasks.where((task) {
        return task.status == TaskStatus.completedActive ||
            task.status == TaskStatus.archived;
      }).toList();

      final totalCount = totalTasks.length;
      final completedCount = completedTasks.length;

      // 计算进度百分比
      final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

      return ProgressStatistics(
        completedCount: completedCount,
        totalCount: totalCount,
        progress: progress,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[ProjectStatisticsUtils] {event: calculation:failed, type: project, id: $projectId, error: $e, stackTrace: $stackTrace}',
        );
      }
      // 返回默认值
      return const ProgressStatistics(
        completedCount: 0,
        totalCount: 0,
        progress: 0.0,
      );
    }
  }

  /// 计算里程碑进度
  ///
  /// [milestoneId] 里程碑ID
  /// [tasks] 里程碑下的所有任务列表
  ///
  /// 返回进度统计结果
  ///
  /// 统计规则：与项目进度统计规则一致
  static ProgressStatistics calculateMilestoneProgress(
    String milestoneId,
    List<Task> tasks,
  ) {
    try {
      // 过滤出属于该里程碑的任务
      final milestoneTasks = tasks.where((task) => task.milestoneId == milestoneId).toList();

      // 计算总任务数：包括 pending、doing、paused、completedActive、archived
      final totalTasks = milestoneTasks.where((task) {
        return task.status == TaskStatus.pending ||
            task.status == TaskStatus.doing ||
            task.status == TaskStatus.paused ||
            task.status == TaskStatus.completedActive ||
            task.status == TaskStatus.archived;
      }).toList();

      // 计算已完成任务数：包括 completedActive、archived
      final completedTasks = totalTasks.where((task) {
        return task.status == TaskStatus.completedActive ||
            task.status == TaskStatus.archived;
      }).toList();

      final totalCount = totalTasks.length;
      final completedCount = completedTasks.length;

      // 计算进度百分比
      final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

      return ProgressStatistics(
        completedCount: completedCount,
        totalCount: totalCount,
        progress: progress,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[ProjectStatisticsUtils] {event: calculation:failed, type: milestone, id: $milestoneId, error: $e, stackTrace: $stackTrace}',
        );
      }
      // 返回默认值
      return const ProgressStatistics(
        completedCount: 0,
        totalCount: 0,
        progress: 0.0,
      );
    }
  }
}

