import 'package:flutter/material.dart';

import '../../core/constants/font_scale_level.dart';

@immutable
class Preference {
  const Preference({
    required this.id,
    required this.localeCode,
    required this.themeMode,
    required this.fontScaleLevel,
    required this.pomodoroTickSoundEnabled,
    required this.updatedAt,
  });

  final int id;
  final String localeCode;
  final ThemeMode themeMode;
  final FontScaleLevel fontScaleLevel;
  final bool pomodoroTickSoundEnabled;
  final DateTime updatedAt;

  Preference copyWith({
    String? localeCode,
    ThemeMode? themeMode,
    FontScaleLevel? fontScaleLevel,
    bool? pomodoroTickSoundEnabled,
    DateTime? updatedAt,
  }) {
    return Preference(
      id: id,
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      fontScaleLevel: fontScaleLevel ?? this.fontScaleLevel,
      pomodoroTickSoundEnabled: pomodoroTickSoundEnabled ?? this.pomodoroTickSoundEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PreferenceUpdate {
  const PreferenceUpdate({
    this.localeCode,
    this.themeMode,
    this.fontScaleLevel,
    this.pomodoroTickSoundEnabled,
  });

  final String? localeCode;
  final ThemeMode? themeMode;
  final FontScaleLevel? fontScaleLevel;
  final bool? pomodoroTickSoundEnabled;
}
