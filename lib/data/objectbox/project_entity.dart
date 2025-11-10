import 'package:objectbox/objectbox.dart';

@Entity()
class ProjectEntity {
  ProjectEntity({
    this.obxId = 0,
    required this.id,
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

  // 日志记录存储在 `ProjectLogEntity` 中，通过 projectId 关联。
}
