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

  late DateTime createdAt;

  late DateTime updatedAt;

  @Index()
  int? parentId;

  double sortIndex = 0;

  List<String> tags = <String>[];

  int templateLockCount = 0;

  String? seedSlug;

  bool allowInstantComplete = false;
}
