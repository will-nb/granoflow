import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/font_scale_level.dart';
import '../services/preference_service.dart';
import 'service_providers.dart';

class PreferenceActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<PreferenceService> get _service async => await ref.read(preferenceServiceProvider.future);

  Future<void> updateLocale(String localeCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await _service;
      return service.updateLocale(localeCode);
    });
  }

  Future<void> updateTheme(ThemeMode mode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await _service;
      return service.updateTheme(mode);
    });
  }

  Future<void> updateFontScaleLevel(FontScaleLevel level) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = await _service;
      return service.updateFontScaleLevel(level);
    });
  }
}

final preferenceActionsNotifierProvider =
    AsyncNotifierProvider<PreferenceActionsNotifier, void>(() {
      return PreferenceActionsNotifier();
    });

