import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/constants/font_scale_constants.dart';

part 'preference_entity.g.dart';

@collection
class PreferenceEntity {
  PreferenceEntity();

  Id id = 0;

  late String localeCode;

  @enumerated
  late ThemeMode themeMode;

  double fontScale = FontScaleConstants.defaultFontScale;

  late DateTime updatedAt;
}
