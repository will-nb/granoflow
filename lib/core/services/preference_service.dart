import 'package:flutter/material.dart';

import '../../core/constants/font_scale_level.dart';
import '../../data/models/preference.dart';
import '../../data/repositories/preference_repository.dart';

class PreferenceService {
  PreferenceService({required PreferenceRepository repository})
    : _repository = repository;

  final PreferenceRepository _repository;

  Stream<Preference> watch() => _repository.watch();

  Future<void> update(PreferenceUpdate update) => _repository.update(update);

  Future<void> updateLocale(String localeCode) {
    return update(PreferenceUpdate(localeCode: localeCode));
  }

  Future<void> updateTheme(ThemeMode mode) {
    return update(PreferenceUpdate(themeMode: mode));
  }

  Future<void> updateFontScaleLevel(FontScaleLevel level) {
    return update(PreferenceUpdate(fontScaleLevel: level));
  }

  Future<void> updateClockTickSoundEnabled(bool enabled) {
    return update(PreferenceUpdate(clockTickSoundEnabled: enabled));
  }
}
