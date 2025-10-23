import 'package:isar/isar.dart';

part 'focus_session_entity.g.dart';

@collection
class FocusSessionEntity {
  FocusSessionEntity();

  Id id = Isar.autoIncrement;

  late int taskId;

  late DateTime startedAt;

  DateTime? endedAt;

  int actualMinutes = 0;

  int? estimateMinutes;

  bool alarmEnabled = false;

  int? transferredToTaskId;

  String? reflectionNote;
}
