import 'package:flutter/foundation.dart';

/// 任务日志条目
/// 记录任务的操作历史
@immutable
class TaskLogEntry {
  const TaskLogEntry({
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

  TaskLogEntry copyWith({
    DateTime? timestamp,
    String? action,
    String? previous,
    String? next,
    String? actor,
  }) {
    return TaskLogEntry(
      timestamp: timestamp ?? this.timestamp,
      action: action ?? this.action,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      actor: actor ?? this.actor,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TaskLogEntry &&
        other.timestamp == timestamp &&
        other.action == action &&
        other.previous == previous &&
        other.next == next &&
        other.actor == actor;
  }

  @override
  int get hashCode => Object.hash(timestamp, action, previous, next, actor);
}

