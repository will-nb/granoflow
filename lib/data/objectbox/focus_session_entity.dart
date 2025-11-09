import 'package:objectbox/objectbox.dart';

import 'task_entity.dart';

@Entity()
class FocusSessionEntity {
  FocusSessionEntity({
    this.obxId = 0,
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

  @Id()
  int obxId;

  @Unique()
  String id;

  String taskId;

  final task = ToOne<TaskEntity>();

  DateTime startedAt;
  DateTime? endedAt;

  int actualMinutes;
  int? estimateMinutes;

  bool alarmEnabled;

  String? transferredToTaskId;

  final transferredToTask = ToOne<TaskEntity>();

  String? reflectionNote;
}
