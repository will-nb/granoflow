import 'package:objectbox/objectbox.dart';

import 'project_entity.dart';

@Entity()
class MilestoneEntity {
  MilestoneEntity({
    this.obxId = 0,
    required this.id,
    required this.projectId,
    required this.title,
    required this.statusIndex,
    this.dueAt,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
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

  String projectId;

  final project = ToOne<ProjectEntity>();

  String title;

  int statusIndex;

  DateTime? dueAt;
  DateTime? startedAt;
  DateTime? endedAt;
  DateTime createdAt;
  DateTime updatedAt;
  double sortIndex;

  List<String> tags;

  int templateLockCount;
  String? seedSlug;
  bool allowInstantComplete;
  String? description;

  // 日志记录存储在 `MilestoneLogEntity` 中，通过 milestoneId 关联。
}
