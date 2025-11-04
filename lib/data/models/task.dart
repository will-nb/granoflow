import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'task_log_entry.dart';

export 'task_log_entry.dart';
export 'task_update.dart';

enum TaskStatus {
  inbox,
  pending,
  doing,
  completedActive,
  archived,
  trashed,
  pseudoDeleted,
}

enum TaskSection {
  overdue,
  today,
  tomorrow,
  thisWeek,
  thisMonth,
  nextMonth,
  later,
  completed,
  archived,
  trash,
}

// TaskLogEntry 已移至 task_log_entry.dart

@immutable
class Task {
  const Task({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.archivedAt,
    this.parentId,
    this.parentTaskId,
    this.projectId,
    this.milestoneId,
    this.sortIndex = 0,
    this.tags = const <String>[],
    this.templateLockCount = 0,
    this.seedSlug,
    this.allowInstantComplete = false,
    this.description,
    this.logs = const <TaskLogEntry>[],
  });

  final int id;
  final String taskId;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? parentId;
  final int? parentTaskId;
  final String? projectId;
  final String? milestoneId;
  final double sortIndex;
  final List<String> tags;
  final int templateLockCount;
  final String? seedSlug;
  final bool allowInstantComplete;
  final String? description;
  final List<TaskLogEntry> logs;

  Task copyWith({
    int? id,
    String? taskId,
    String? title,
    TaskStatus? status,
    DateTime? dueAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? parentId,
    int? parentTaskId,
    String? projectId,
    String? milestoneId,
    double? sortIndex,
    List<String>? tags,
    int? templateLockCount,
    String? seedSlug,
    bool? allowInstantComplete,
    String? description,
    List<TaskLogEntry>? logs,
  }) {
    return Task(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      projectId: projectId ?? this.projectId,
      milestoneId: milestoneId ?? this.milestoneId,
      sortIndex: sortIndex ?? this.sortIndex,
      tags: tags ?? this.tags,
      templateLockCount: templateLockCount ?? this.templateLockCount,
      seedSlug: seedSlug ?? this.seedSlug,
      allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
      description: description ?? this.description,
      logs: logs ?? this.logs,
    );
  }

  bool get canEditStructure =>
      status != TaskStatus.completedActive &&
      status != TaskStatus.archived &&
      templateLockCount == 0;

  bool get isLeaf => parentId == null;

  @override
  int get hashCode => Object.hashAll([
    id,
    taskId,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    archivedAt,
    createdAt,
    updatedAt,
    parentId,
    sortIndex,
    const ListEquality<String>().hash(tags),
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
    parentTaskId,
    projectId,
    milestoneId,
    const ListEquality<TaskLogEntry>().hash(logs),
  ]);

  @override
  bool operator ==(Object other) {
    return other is Task &&
        other.id == id &&
        other.taskId == taskId &&
        other.title == title &&
        other.status == status &&
        other.dueAt == dueAt &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.archivedAt == archivedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.parentId == parentId &&
        other.parentTaskId == parentTaskId &&
        other.projectId == projectId &&
        other.milestoneId == milestoneId &&
        other.sortIndex == sortIndex &&
        const ListEquality<String>().equals(other.tags, tags) &&
        other.templateLockCount == templateLockCount &&
        other.seedSlug == seedSlug &&
        other.allowInstantComplete == allowInstantComplete &&
        other.description == description &&
        const ListEquality<TaskLogEntry>().equals(other.logs, logs);
  }

  @override
  String toString() => 'Task(id: $id, taskId: $taskId, title: $title)';
}

@immutable
class TaskTreeNode {
  const TaskTreeNode({
    required this.task,
    this.children = const <TaskTreeNode>[],
  });

  final Task task;
  final List<TaskTreeNode> children;

  TaskTreeNode copyWith({Task? task, List<TaskTreeNode>? children}) {
    return TaskTreeNode(
      task: task ?? this.task,
      children: children ?? this.children,
    );
  }
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.status,
    this.dueAt,
    this.parentId,
    this.parentTaskId,
    this.projectId,
    this.milestoneId,
    this.tags = const <String>[],
    this.sortIndex = 0,
    this.seedSlug,
    this.allowInstantComplete = false,
    this.description,
    this.logs = const <TaskLogEntry>[],
  });

  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final int? parentId;
  final int? parentTaskId;
  final String? projectId;
  final String? milestoneId;
  final List<String> tags;
  final double sortIndex;
  final String? seedSlug;
  final bool allowInstantComplete;
  final String? description;
  final List<TaskLogEntry> logs;
}

// TaskUpdate 已移至 task_update.dart
