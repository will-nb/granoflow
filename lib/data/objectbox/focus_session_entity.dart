import 'package:objectbox/objectbox.dart';

import 'task_entity.dart';

@Entity()
class FocusSessionEntity {
  FocusSessionEntity({
    this.obxId = 0,
    required this.id,
    this.taskId,
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

  // taskId 用于存储业务 ID（可选），task 关系用于 ObjectBox 关联
  // 注意：taskId 是可选的，因为 ObjectBox 关系字段会自动管理关联
  String? taskId;

  final task = ToOne<TaskEntity>();

  @Property(type: PropertyType.date)
  DateTime startedAt;
  
  @Property(type: PropertyType.date)
  DateTime? endedAt;

  int actualMinutes;
  int? estimateMinutes;

  bool alarmEnabled;

  String? transferredToTaskId;

  final transferredToTask = ToOne<TaskEntity>();

  String? reflectionNote;
}
