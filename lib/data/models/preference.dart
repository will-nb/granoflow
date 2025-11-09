import 'package:flutter/material.dart';

import '../../core/constants/font_scale_level.dart';

@immutable
class Preference {
  const Preference({
    required this.id,
    required this.localeCode,
    required this.themeMode,
    required this.fontScaleLevel,
    required this.clockTickSoundEnabled,
    required this.updatedAt,
  });

  final String id;
  final String localeCode;
  final ThemeMode themeMode;
  final FontScaleLevel fontScaleLevel;
  final bool clockTickSoundEnabled;
  final DateTime updatedAt;

  Preference copyWith({
    String? localeCode,
    ThemeMode? themeMode,
    FontScaleLevel? fontScaleLevel,
    bool? clockTickSoundEnabled,
    DateTime? updatedAt,
  }) {
    return Preference(
      id: id,
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      fontScaleLevel: fontScaleLevel ?? this.fontScaleLevel,
      clockTickSoundEnabled: clockTickSoundEnabled ?? this.clockTickSoundEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PreferenceUpdate {
  const PreferenceUpdate({
    this.localeCode,
    this.themeMode,
    this.fontScaleLevel,
    this.clockTickSoundEnabled,
  });

  final String? localeCode;
  final ThemeMode? themeMode;
  final FontScaleLevel? fontScaleLevel;
  final bool? clockTickSoundEnabled;
}
