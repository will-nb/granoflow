import 'package:objectbox/objectbox.dart';

import 'project_entity.dart';

@Entity()
class ProjectLogEntity {
  ProjectLogEntity({
    this.obxId = 0,
    required this.id,
    this.projectId,
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

  // projectId 用于存储业务 ID（可选），project 关系用于 ObjectBox 关联
  String? projectId;

  final project = ToOne<ProjectEntity>();

  @Property(type: PropertyType.date)
  DateTime timestamp;
  String action;
  String? previous;
  String? next;
  String? actor;
}
