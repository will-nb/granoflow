import 'package:objectbox/objectbox.dart';

import 'task_entity.dart';

@Entity()
class TaskLogEntity {
  TaskLogEntity({
    this.obxId = 0,
    required this.id,
    this.taskId,
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

  // taskId 用于存储业务 ID（可选），task 关系用于 ObjectBox 关联
  String? taskId;

  final task = ToOne<TaskEntity>();

  @Property(type: PropertyType.date)
  DateTime timestamp;
  String action;
  String? previous;
  String? next;
  String? actor;
}
