import 'package:drift/drift.dart';

/// ProjectLogs 表定义
class ProjectLogs extends Table {
  @override
  String get tableName => 'project_logs';

  TextColumn get id => text()();
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get action => text()();
  TextColumn get previous => text().nullable()();
  TextColumn get next => text().nullable()();
  TextColumn get actor => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
