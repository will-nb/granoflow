import 'package:drift/drift.dart';

import '../converters.dart';

/// TaskTemplates 表定义
class TaskTemplates extends Table {
  @override
  String get tableName => 'task_templates';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get parentTaskId => text().nullable()();
  TextColumn get defaultTags => text().map(const ListStringTypeConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  TextColumn get seedSlug => text().nullable()();
  IntColumn get suggestedEstimateMinutes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ListStringTypeConverter 已移至 converters.dart
