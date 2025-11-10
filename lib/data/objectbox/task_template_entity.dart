import 'package:objectbox/objectbox.dart';

import 'task_entity.dart';

@Entity()
class TaskTemplateEntity {
  TaskTemplateEntity({
    this.obxId = 0,
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.parentTaskId,
    List<String>? defaultTags,
    this.lastUsedAt,
    this.seedSlug,
    this.suggestedEstimateMinutes,
  }) : defaultTags = defaultTags ?? <String>[];

  @Id()
  int obxId;

  @Unique()
  String id;

  String title;

  String? parentTaskId;

  final parentTask = ToOne<TaskEntity>();

  List<String> defaultTags;

  @Property(type: PropertyType.date)
  DateTime createdAt;
  
  @Property(type: PropertyType.date)
  DateTime updatedAt;
  
  @Property(type: PropertyType.date)
  DateTime? lastUsedAt;

  String? seedSlug;

  int? suggestedEstimateMinutes;
}
