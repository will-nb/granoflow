import 'package:objectbox/objectbox.dart';

import 'milestone_entity.dart';

@Entity()
class MilestoneLogEntity {
  MilestoneLogEntity({
    this.obxId = 0,
    required this.id,
    required this.milestoneId,
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

  String milestoneId;

  final milestone = ToOne<MilestoneEntity>();

  DateTime timestamp;
  String action;
  String? previous;
  String? next;
  String? actor;
}
