import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/font_scale_level.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

final appLocaleProvider = StreamProvider<Locale>((ref) async* {
  final preferenceService = await ref.read(preferenceServiceProvider.future);
  yield* preferenceService.watch().map((pref) {
    final parts = pref.localeCode.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(pref.localeCode);
    }
  });
});

final themeProvider = StreamProvider<ThemeMode>((ref) async* {
  final preferenceService = await ref.read(preferenceServiceProvider.future);
  yield* preferenceService.watch().map((pref) => pref.themeMode);
});

final fontScaleLevelProvider = StreamProvider<FontScaleLevel>((ref) async* {
  final preferenceService = await ref.read(preferenceServiceProvider.future);
  yield* preferenceService.watch().map((pref) => pref.fontScaleLevel);
});

final seedInitializerProvider = FutureProvider<void>((ref) async {
  debugPrint('🔵 SeedInitializerProvider: Starting initialization...');
  ref.keepAlive();
  
  try {
    debugPrint('🔵 SeedInitializerProvider: Reading seedImportServiceProvider...');
    final service = await ref.read(seedImportServiceProvider.future);
    debugPrint('🔵 SeedInitializerProvider: SeedImportService obtained');

    // 等待 appLocaleProvider 加载完成，而不是使用默认值
    // 使用 ref.read 而不是 ref.watch，避免 locale 变化时重复触发导入
    debugPrint('🔵 SeedInitializerProvider: Reading appLocaleProvider...');
    final localeAsync = ref.read(appLocaleProvider);
    debugPrint('🔵 SeedInitializerProvider: appLocaleProvider state: ${localeAsync.runtimeType}');
    
    final localeValue = await localeAsync.when(
      data: (value) {
        debugPrint('🔵 SeedInitializerProvider: Locale from appLocaleProvider: $value');
        return Future.value(value);
      },
      loading: () async {
        debugPrint('🔵 SeedInitializerProvider: appLocaleProvider is loading, reading from PreferenceRepository...');
        // 如果还在加载，直接从 PreferenceRepository 加载
        final prefRepo = await ref.read(preferenceRepositoryProvider.future);
        final pref = await prefRepo.load();
        final parts = pref.localeCode.split('_');
        final locale = parts.length == 2
            ? Locale(parts[0], parts[1])
            : Locale(pref.localeCode);
        debugPrint('🔵 SeedInitializerProvider: Locale from PreferenceRepository: $locale (code: ${pref.localeCode})');
        return locale;
      },
      error: (error, stackTrace) {
        debugPrint('🔵 SeedInitializerProvider: Error reading appLocaleProvider: $error');
        debugPrint('🔵 SeedInitializerProvider: Using default locale: en');
        return Future.value(const Locale('en'));
      },
    );

    // 构造完整的 locale 代码 (如 zh_CN, zh_HK, en)
    final locale = localeValue.countryCode != null
        ? '${localeValue.languageCode}_${localeValue.countryCode}'
        : localeValue.languageCode;
    
    debugPrint('🔵 SeedInitializerProvider: Calling importIfNeeded with locale: $locale');
    await service.importIfNeeded(locale);
    debugPrint('🔵 SeedInitializerProvider: importIfNeeded completed successfully');
  } catch (error, stackTrace) {
    debugPrint('🔴 SeedInitializerProvider: ERROR - Failed to initialize seed import');
    debugPrint('🔴 SeedInitializerProvider: Error: $error');
    debugPrint('🔴 SeedInitializerProvider: Error type: ${error.runtimeType}');
    debugPrint('🔴 SeedInitializerProvider: Stack trace: $stackTrace');
    rethrow;
  }
});

