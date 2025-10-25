import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

part 'preference_entity.g.dart';

@collection
class PreferenceEntity {
  PreferenceEntity();

  Id id = 0;

  late String localeCode;

  @enumerated
  late ThemeMode themeMode;

  double fontScale = 1.0;

  late DateTime updatedAt;
}
