import 'package:drift/drift.dart';

/// SeedImportLogs 表定义
class SeedImportLogs extends Table {
  @override
  String get tableName => 'seed_import_logs';

  TextColumn get id => text()();
  TextColumn get version => text()();
  DateTimeColumn get importedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
