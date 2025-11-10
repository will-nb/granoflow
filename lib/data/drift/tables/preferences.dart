import 'package:drift/drift.dart';

/// Preferences 表定义
class Preferences extends Table {
  @override
  String get tableName => 'preferences';

  TextColumn get id => text().withDefault(const Constant('default'))();
  TextColumn get localeCode => text()();
  IntColumn get themeModeIndex => integer()();
  TextColumn get fontScaleLevel => text()();
  BoolColumn get clockTickSoundEnabled => boolean()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
