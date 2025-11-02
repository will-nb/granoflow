import 'package:isar/isar.dart';

import '../models/task.dart';

part 'milestone_entity.g.dart';

@collection
class MilestoneEntity {
  MilestoneEntity();

  Id id = Isar.autoIncrement;

  late String milestoneId;

  @Index()
  int? projectIsarId;

  @Index()
  late String projectId;

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
  double sortIndex = 0;

  List<String> tags = <String>[];

  int templateLockCount = 0;

  String? seedSlug;

  bool allowInstantComplete = false;

  String? description;

  List<MilestoneLogEntryEntity> logs = <MilestoneLogEntryEntity>[];
}

@embedded
class MilestoneLogEntryEntity {
  late DateTime timestamp;
  late String action;
  String? previous;
  String? next;
  String? actor;
}
