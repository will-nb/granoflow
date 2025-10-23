import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

enum TaskStatus {
  inbox,
  pending,
  doing,
  completedActive,
  archived,
  trashed,
  pseudoDeleted,
}

enum TaskSection { today, tomorrow, later, completed, archived, trash }

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
    this.parentId,
    this.sortIndex = 0,
    this.tags = const <String>[],
    this.templateLockCount = 0,
    this.seedSlug,
    this.allowInstantComplete = false,
  });

  final int id;
  final String taskId;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? parentId;
  final double sortIndex;
  final List<String> tags;
  final int templateLockCount;
  final String? seedSlug;
  final bool allowInstantComplete;

  Task copyWith({
    int? id,
    String? taskId,
    String? title,
    TaskStatus? status,
    DateTime? dueAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? parentId,
    double? sortIndex,
    List<String>? tags,
    int? templateLockCount,
    String? seedSlug,
    bool? allowInstantComplete,
  }) {
    return Task(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      sortIndex: sortIndex ?? this.sortIndex,
      tags: tags ?? this.tags,
      templateLockCount: templateLockCount ?? this.templateLockCount,
      seedSlug: seedSlug ?? this.seedSlug,
      allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
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
    createdAt,
    updatedAt,
    parentId,
    sortIndex,
    const ListEquality<String>().hash(tags),
    templateLockCount,
    seedSlug,
    allowInstantComplete,
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
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.parentId == parentId &&
        other.sortIndex == sortIndex &&
        const ListEquality<String>().equals(other.tags, tags) &&
        other.templateLockCount == templateLockCount &&
        other.seedSlug == seedSlug &&
        other.allowInstantComplete == allowInstantComplete;
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
    this.tags = const <String>[],
    this.sortIndex = 0,
    this.seedSlug,
    this.allowInstantComplete = false,
  });

  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final int? parentId;
  final List<String> tags;
  final double sortIndex;
  final String? seedSlug;
  final bool allowInstantComplete;
}

class TaskUpdate {
  const TaskUpdate({
    this.title,
    this.status,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.parentId,
    this.sortIndex,
    this.tags,
    this.templateLockDelta = 0,
    this.allowInstantComplete,
  });

  final String? title;
  final TaskStatus? status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? parentId;
  final double? sortIndex;
  final List<String>? tags;
  final int templateLockDelta;
  final bool? allowInstantComplete;
}
