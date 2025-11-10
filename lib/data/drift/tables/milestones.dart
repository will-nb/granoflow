import 'package:drift/drift.dart';

import '../converters.dart';
import '../../models/task.dart';
import 'projects.dart';

/// Milestones 表定义
class Milestones extends Table {
  @override
  String get tableName => 'milestones';

  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();
  TextColumn get title => text()();
  IntColumn get status => intEnum<TaskStatus>()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  RealColumn get sortIndex => real()();
  TextColumn get tags => text().map(const ListStringTypeConverter())();
  IntColumn get templateLockCount => integer()();
  TextColumn get seedSlug => text().nullable()();
  BoolColumn get allowInstantComplete => boolean()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ListStringTypeConverter 已移至 converters.dart
