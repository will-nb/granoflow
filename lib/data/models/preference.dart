import 'package:flutter/material.dart';

@immutable
class Preference {
  const Preference({
    required this.id,
    required this.localeCode,
    required this.themeMode,
    required this.fontScale,
    required this.updatedAt,
  });

  final int id;
  final String localeCode;
  final ThemeMode themeMode;
  final double fontScale;
  final DateTime updatedAt;

  Preference copyWith({
    String? localeCode,
    ThemeMode? themeMode,
    double? fontScale,
    DateTime? updatedAt,
  }) {
    return Preference(
      id: id,
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PreferenceUpdate {
  const PreferenceUpdate({this.localeCode, this.themeMode, this.fontScale});

  final String? localeCode;
  final ThemeMode? themeMode;
  final double? fontScale;
}
