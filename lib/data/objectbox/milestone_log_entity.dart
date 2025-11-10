import 'package:objectbox/objectbox.dart';

import 'milestone_entity.dart';

@Entity()
class MilestoneLogEntity {
  MilestoneLogEntity({
    this.obxId = 0,
    required this.id,
    this.milestoneId,
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

  // milestoneId 用于存储业务 ID（可选），milestone 关系用于 ObjectBox 关联
  String? milestoneId;

  final milestone = ToOne<MilestoneEntity>();

  @Property(type: PropertyType.date)
  DateTime timestamp;
  String action;
  String? previous;
  String? next;
  String? actor;
}
