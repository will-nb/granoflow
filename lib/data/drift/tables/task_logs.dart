import 'package:drift/drift.dart';

import 'tasks.dart';

/// TaskLogs 表定义
class TaskLogs extends Table {
  @override
  String get tableName => 'task_logs';

  TextColumn get id => text()();
  TextColumn get taskId => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get action => text()();
  TextColumn get previous => text().nullable()();
  TextColumn get next => text().nullable()();
  TextColumn get actor => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
