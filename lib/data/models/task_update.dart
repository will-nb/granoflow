import 'task.dart';

/// 任务更新数据类
/// 用于表示任务的部分更新操作
class TaskUpdate {
  const TaskUpdate({
    this.title,
    this.status,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.archivedAt,
    this.projectId,
    this.milestoneId,
    this.sortIndex,
    this.tags,
    this.templateLockDelta = 0,
    this.allowInstantComplete,
    this.description,
    this.logs,
    this.clearProject,
    this.clearMilestone,
  });

  final String? title;
  final TaskStatus? status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? archivedAt;
  final String? projectId;
  final String? milestoneId;
  final double? sortIndex;
  final List<String>? tags;
  final int templateLockDelta;
  final bool? allowInstantComplete;
  final String? description;
  final List<TaskLogEntry>? logs;

  /// 当需要显式将 projectId 置为 null 时，传 true。
  final bool? clearProject;

  /// 当需要显式将 milestoneId 置为 null 时，传 true。
  final bool? clearMilestone;
}

