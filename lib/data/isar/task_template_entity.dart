import 'package:isar/isar.dart';

part 'task_template_entity.g.dart';

@collection
class TaskTemplateEntity {
  TaskTemplateEntity();

  Id id = Isar.autoIncrement;

  late String title;

  int? parentTaskId;

  List<String> defaultTags = <String>[];

  late DateTime createdAt;

  late DateTime updatedAt;

  DateTime? lastUsedAt;

  String? seedSlug;

  int? suggestedEstimateMinutes;
}
