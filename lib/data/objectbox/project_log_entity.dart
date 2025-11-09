import 'package:objectbox/objectbox.dart';

import 'project_entity.dart';

@Entity()
class ProjectLogEntity {
  ProjectLogEntity({
    this.obxId = 0,
    required this.id,
    required this.projectId,
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

  String projectId;

  final project = ToOne<ProjectEntity>();

  DateTime timestamp;
  String action;
  String? previous;
  String? next;
  String? actor;
}
