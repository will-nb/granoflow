import 'package:drift/drift.dart';

import '../../models/node.dart';

/// Nodes 表定义
class Nodes extends Table {
  @override
  String get tableName => 'nodes';

  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get taskId => text()();
  TextColumn get title => text()();
  IntColumn get status => intEnum<NodeStatus>()();
  RealColumn get sortIndex => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

