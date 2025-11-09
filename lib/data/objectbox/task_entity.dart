import 'package:objectbox/objectbox.dart';

import 'milestone_entity.dart';
import 'project_entity.dart';

@Entity()
class TaskEntity {
  TaskEntity({
    this.obxId = 0,
    required this.id,
    required this.title,
    required this.statusIndex,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.projectId,
    this.milestoneId,
    this.sortIndex = 0,
    List<String>? tags,
    this.templateLockCount = 0,
    this.seedSlug,
    this.allowInstantComplete = false,
    this.description,
  }) : tags = tags ?? <String>[];

  @Id()
  int obxId;

  @Unique()
  String id;

  String title;

  int statusIndex;

  DateTime? dueAt;
  DateTime? startedAt;
  DateTime? endedAt;
  DateTime? archivedAt;
  DateTime createdAt;
  DateTime updatedAt;

  String? parentId;
  String? projectId;
  String? milestoneId;

  final project = ToOne<ProjectEntity>();

  final parent = ToOne<TaskEntity>();

  final milestone = ToOne<MilestoneEntity>();

  @Backlink('parent')
  final children = ToMany<TaskEntity>();

  double sortIndex;

  List<String> tags;

  int templateLockCount;
  String? seedSlug;
  bool allowInstantComplete;
  String? description;

  // 日志记录存储在 `TaskLogEntity` 中，通过 taskId 关联。
}
