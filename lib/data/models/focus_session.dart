import 'package:flutter/foundation.dart';

@immutable
class FocusSession {
  const FocusSession({
    required this.id,
    required this.taskId,
    required this.startedAt,
    this.endedAt,
    this.actualMinutes = 0,
    this.estimateMinutes,
    this.alarmEnabled = false,
    this.transferredToTaskId,
    this.reflectionNote,
  });

  final int id;
  final int taskId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int actualMinutes;
  final int? estimateMinutes;
  final bool alarmEnabled;
  final int? transferredToTaskId;
  final String? reflectionNote;

  bool get isActive => endedAt == null;

  FocusSession copyWith({
    int? id,
    int? taskId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? actualMinutes,
    int? estimateMinutes,
    bool? alarmEnabled,
    int? transferredToTaskId,
    String? reflectionNote,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      transferredToTaskId: transferredToTaskId ?? this.transferredToTaskId,
      reflectionNote: reflectionNote ?? this.reflectionNote,
    );
  }
}
