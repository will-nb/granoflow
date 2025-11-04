import 'package:flutter/material.dart';

import 'app_theme_dark.dart';
import 'app_theme_light.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => AppThemeLight.build();

  static ThemeData dark() => AppThemeDark.build();
}
