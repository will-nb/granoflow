import 'package:drift/drift.dart';

import '../converters.dart';

/// Tags 表定义
class Tags extends Table {
  @override
  String get tableName => 'tags';

  TextColumn get id => text()();
  TextColumn get slug => text()();
  IntColumn get kindIndex => integer()();
  TextColumn get localizedLabelsJson => text().map(const MapStringStringTypeConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {slug},
      ];
}

// MapStringStringTypeConverter 已移至 converters.dart
