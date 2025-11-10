import 'package:drift/drift.dart';

/// MilestoneLogs 表定义
class MilestoneLogs extends Table {
  @override
  String get tableName => 'milestone_logs';

  TextColumn get id => text()();
  TextColumn get milestoneId => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get action => text()();
  TextColumn get previous => text().nullable()();
  TextColumn get next => text().nullable()();
  TextColumn get actor => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
