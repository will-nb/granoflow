import 'package:drift/drift.dart';

import '../converters.dart';
import '../../models/task.dart';

/// Tasks 表定义
class Tasks extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get status => intEnum<TaskStatus>()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get projectId => text().nullable()();
  TextColumn get milestoneId => text().nullable()();
  RealColumn get sortIndex => real()();
  TextColumn get tags => text().map(const ListStringTypeConverter())();
  IntColumn get templateLockCount => integer()();
  TextColumn get seedSlug => text().nullable()();
  BoolColumn get allowInstantComplete => boolean()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// List<String> 转换器（用于 tags 字段）
class ListStringConverter extends TypeConverter<List<String>, String> {
  const ListStringConverter();

  @override
  List<String> fromSql(String fromDb) {
    return listStringFromJson(fromDb);
  }

  @override
  String toSql(List<String> value) {
    return listStringToJson(value);
  }
}
