import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/font_scale_level.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

final appLocaleProvider = StreamProvider<Locale>((ref) {
  return ref.watch(preferenceServiceProvider).watch().map((pref) {
    final parts = pref.localeCode.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(pref.localeCode);
    }
  });
});

final themeProvider = StreamProvider<ThemeMode>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) => pref.themeMode);
});

final fontScaleLevelProvider = StreamProvider<FontScaleLevel>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) => pref.fontScaleLevel);
});

final seedInitializerProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  final service = ref.watch(seedImportServiceProvider);

  // 等待 appLocaleProvider 加载完成，而不是使用默认值
  // 使用 ref.read 而不是 ref.watch，避免 locale 变化时重复触发导入
  final localeAsync = ref.read(appLocaleProvider);
  final localeValue = await localeAsync.when(
    data: (value) => Future.value(value),
    loading: () async {
      // 如果还在加载，直接从 PreferenceRepository 加载
      final pref = await ref.read(preferenceRepositoryProvider).load();
      final parts = pref.localeCode.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      } else {
        return Locale(pref.localeCode);
      }
    },
    error: (_, __) => Future.value(const Locale('en')),
  );

  // 构造完整的 locale 代码 (如 zh_CN, zh_HK, en)
  final locale = localeValue.countryCode != null
      ? '${localeValue.languageCode}_${localeValue.countryCode}'
      : localeValue.languageCode;

  await service.importIfNeeded(locale);
});

