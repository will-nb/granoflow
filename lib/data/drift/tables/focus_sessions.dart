import 'package:drift/drift.dart';

import 'tasks.dart';

/// FocusSessions 表定义
class FocusSessions extends Table {
  @override
  String get tableName => 'focus_sessions';

  TextColumn get id => text()();
  TextColumn get taskId => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get actualMinutes => integer()();
  IntColumn get estimateMinutes => integer().nullable()();
  BoolColumn get alarmEnabled => boolean()();
  TextColumn get transferredToTaskId => text().nullable()();
  TextColumn get reflectionNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
