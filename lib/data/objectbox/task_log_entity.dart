import 'package:objectbox/objectbox.dart';

import 'task_entity.dart';

@Entity()
class TaskLogEntity {
  TaskLogEntity({
    this.obxId = 0,
    required this.id,
    required this.taskId,
    required this.timestamp,
    required this.action,
    this.previous,
    this.next,
    this.actor,
  });

  @Id()
  int obxId;

  @Unique()
  String id;

  String taskId;

  final task = ToOne<TaskEntity>();

  DateTime timestamp;
  String action;
  String? previous;
  String? next;
  String? actor;
}
