import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../../core/constants/font_scale_level.dart';

part 'preference_entity.g.dart';

@collection
class PreferenceEntity {
  PreferenceEntity();

  Id id = 0;

  late String localeCode;

  @enumerated
  late ThemeMode themeMode;

  /// 字体大小级别，存储为字符串（enum.name）
  /// 默认值为 medium
  late String fontScaleLevel = FontScaleLevel.medium.name;

  late DateTime updatedAt;
}
