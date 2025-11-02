import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'task.dart';

@immutable
class MilestoneLogEntry {
  const MilestoneLogEntry({
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

  MilestoneLogEntry copyWith({
    DateTime? timestamp,
    String? action,
    String? previous,
    String? next,
    String? actor,
  }) {
    return MilestoneLogEntry(
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      actor: actor ?? this.actor,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MilestoneLogEntry &&
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
class Milestone {
  const Milestone({
    required this.id,
    required this.milestoneId,
    required this.projectId,
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
    this.logs = const <MilestoneLogEntry>[],
  });

  final int id;
  final String milestoneId;
  final String projectId;
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
  final List<MilestoneLogEntry> logs;

  Milestone copyWith({
    int? id,
    String? milestoneId,
    String? projectId,
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
    List<MilestoneLogEntry>? logs,
  }) {
    return Milestone(
      id: id ?? this.id,
      milestoneId: milestoneId ?? this.milestoneId,
      projectId: projectId ?? this.projectId,
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
    milestoneId,
    projectId,
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
    const ListEquality<MilestoneLogEntry>().hash(logs),
  ]);

  @override
  bool operator ==(Object other) {
    return other is Milestone &&
        other.id == id &&
        other.milestoneId == milestoneId &&
        other.projectId == projectId &&
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
        const ListEquality<MilestoneLogEntry>().equals(other.logs, logs);
  }
}

class MilestoneDraft {
  const MilestoneDraft({
    required this.milestoneId,
    required this.projectId,
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
    this.logs = const <MilestoneLogEntry>[],
  });

  final String milestoneId;
  final String projectId;
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
  final List<MilestoneLogEntry> logs;
}

class MilestoneUpdate {
  const MilestoneUpdate({
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
  final List<MilestoneLogEntry>? logs;
}
