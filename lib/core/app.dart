import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../presentation/navigation/app_router.dart';
import 'constants/font_scale_constants.dart';
import 'providers/app_providers.dart';
import 'providers/service_providers.dart';
import 'theme/app_theme.dart';

class GranoFlowApp extends ConsumerWidget {
  const GranoFlowApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferenceLocale = ref
        .watch(appLocaleProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final localeValue = locale ?? preferenceLocale;
    final themeMode = ref
        .watch(themeProvider)
        .maybeWhen(data: (value) => value, orElse: () => ThemeMode.system);
    final fontScale = ref
        .watch(fontScaleProvider)
        .maybeWhen(data: (value) => value, orElse: () => FontScaleConstants.defaultFontScale);
    final config = ref.watch(appConfigProvider);
    return MaterialApp.router(
      locale: localeValue,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: config.isDevelopment,
      builder: (context, child) {
        // 调试信息：检查系统亮度 (Debug info: Check system brightness)
        if (config.isDevelopment && themeMode == ThemeMode.system) {
          final platformBrightness = MediaQuery.platformBrightnessOf(context);
          debugPrint(
            'GranoFlowApp: ThemeMode=system, PlatformBrightness=$platformBrightness, '
            'EffectiveBrightness=${Theme.of(context).brightness}',
          );
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fontScale)),
          child: child!,
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
