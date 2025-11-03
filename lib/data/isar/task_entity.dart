import 'package:isar/isar.dart';

import '../models/task.dart';

part 'task_entity.g.dart';

@collection
class TaskEntity {
  TaskEntity();

  Id id = Isar.autoIncrement;

  late String taskId;

  late String title;

  @enumerated
  @Index()
  late TaskStatus status;

  @Index()
  DateTime? dueAt;

  DateTime? startedAt;

  DateTime? endedAt;

  DateTime? archivedAt;

  late DateTime createdAt;

  late DateTime updatedAt;

  @Index()
  int? parentId;

  /// 拆表过渡字段：新的父任务引用仅指向普通任务。
  @Index()
  int? parentTaskId;

  /// 任务所属项目的 Isar id（可为空）。
  @Index()
  int? projectIsarId;

  /// 任务所属项目的业务 ID。
  @Index()
  String? projectId;

  /// 任务所属里程碑的 Isar id（可为空）。
  @Index()
  int? milestoneIsarId;

  /// 任务所属里程碑的业务 ID。
  @Index()
  String? milestoneId;

  double sortIndex = 0;

  List<String> tags = <String>[];

  int templateLockCount = 0;

  String? seedSlug;

  bool allowInstantComplete = false;

  String? description;

  List<TaskLogEntryEntity> logs = <TaskLogEntryEntity>[];
}

@embedded
class TaskLogEntryEntity {
  late DateTime timestamp;
  late String action;
  String? previous;
  String? next;
  String? actor;
}
