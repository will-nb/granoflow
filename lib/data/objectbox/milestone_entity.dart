import 'package:objectbox/objectbox.dart';

import 'project_entity.dart';

@Entity()
class MilestoneEntity {
  MilestoneEntity({
    this.obxId = 0,
    required this.id,
    this.projectId,
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

  // projectId 用于存储业务 ID（可选），project 关系用于 ObjectBox 关联
  String? projectId;

  final project = ToOne<ProjectEntity>();

  String title;

  int statusIndex;

  @Property(type: PropertyType.date)
  DateTime? dueAt;
  
  @Property(type: PropertyType.date)
  DateTime? startedAt;
  
  @Property(type: PropertyType.date)
  DateTime? endedAt;
  
  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  double sortIndex;

  List<String> tags;

  int templateLockCount;
  String? seedSlug;
  bool allowInstantComplete;
  String? description;

  // 日志记录存储在 `MilestoneLogEntity` 中，通过 milestoneId 关联。
}
