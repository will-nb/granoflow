import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'task.dart';

@immutable
class ProjectLogEntry {
  const ProjectLogEntry({
    required this.timestamp,
    required this.action,
    this.previous,
    this.next,
    this.actor,
  });

  final DateTime timestamp;
  final String action;
  final String? previous;
  final String? next;
  final String? actor;

  ProjectLogEntry copyWith({
    DateTime? timestamp,
    String? action,
    String? previous,
    String? next,
    String? actor,
  }) {
    return ProjectLogEntry(
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      actor: actor ?? this.actor,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectLogEntry &&
        other.timestamp == timestamp &&
        other.action == action &&
        other.previous == previous &&
        other.next == next &&
        other.actor == actor;
  }

  @override
  int get hashCode => Object.hash(timestamp, action, previous, next, actor);
}

@immutable
class Project {
  const Project({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.sortIndex = 0,
    this.tags = const <String>[],
    this.templateLockCount = 0,
    this.seedSlug,
    this.allowInstantComplete = false,
    this.description,
    this.logs = const <ProjectLogEntry>[],
  });

  final String id;
  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double sortIndex;
  final List<String> tags;
  final int templateLockCount;
  final String? seedSlug;
  final bool allowInstantComplete;
  final String? description;
  final List<ProjectLogEntry> logs;

  Project copyWith({
    String? id,
    String? title,
    TaskStatus? status,
    DateTime? dueAt,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? sortIndex,
    List<String>? tags,
    int? templateLockCount,
    String? seedSlug,
    bool? allowInstantComplete,
    String? description,
    List<ProjectLogEntry>? logs,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      dueAt: dueAt ?? this.dueAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortIndex: sortIndex ?? this.sortIndex,
      tags: tags ?? this.tags,
      templateLockCount: templateLockCount ?? this.templateLockCount,
      seedSlug: seedSlug ?? this.seedSlug,
      allowInstantComplete: allowInstantComplete ?? this.allowInstantComplete,
      description: description ?? this.description,
      logs: logs ?? this.logs,
    );
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    status,
    dueAt,
    startedAt,
    endedAt,
    createdAt,
    updatedAt,
    sortIndex,
    const ListEquality<String>().hash(tags),
    templateLockCount,
    seedSlug,
    allowInstantComplete,
    description,
    const ListEquality<ProjectLogEntry>().hash(logs),
  ]);

  @override
  bool operator ==(Object other) {
    return other is Project &&
        other.id == id &&
        other.title == title &&
        other.status == status &&
        other.dueAt == dueAt &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.sortIndex == sortIndex &&
        const ListEquality<String>().equals(other.tags, tags) &&
        other.templateLockCount == templateLockCount &&
        other.seedSlug == seedSlug &&
        other.allowInstantComplete == allowInstantComplete &&
        other.description == description &&
        const ListEquality<ProjectLogEntry>().equals(other.logs, logs);
  }
}

class ProjectDraft {
  const ProjectDraft({
    required this.title,
    required this.status,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.sortIndex = 0,
    this.tags = const <String>[],
    this.templateLockCount = 0,
    this.seedSlug,
    this.allowInstantComplete = false,
    this.description,
    this.logs = const <ProjectLogEntry>[],
  });

  final String title;
  final TaskStatus status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double sortIndex;
  final List<String> tags;
  final int templateLockCount;
  final String? seedSlug;
  final bool allowInstantComplete;
  final String? description;
  final List<ProjectLogEntry> logs;
}

class ProjectUpdate {
  const ProjectUpdate({
    this.title,
    this.status,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.sortIndex,
    this.tags,
    this.templateLockDelta = 0,
    this.allowInstantComplete,
    this.description,
    this.logs,
    this.seedSlug,
  });

  final String? title;
  final TaskStatus? status;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? sortIndex;
  final List<String>? tags;
  final int templateLockDelta;
  final bool? allowInstantComplete;
  final String? description;
  final List<ProjectLogEntry>? logs;
  final String? seedSlug;
}
