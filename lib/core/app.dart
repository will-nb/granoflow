import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../presentation/navigation/app_router.dart';
import 'constants/font_scale_constants.dart';
import 'providers/app_providers.dart';
import 'providers/service_providers.dart';
import 'providers/system_tray_provider.dart';
import 'theme/app_theme.dart';

class GranoFlowApp extends ConsumerStatefulWidget {
  const GranoFlowApp({super.key, this.locale});

  final Locale? locale;


  @override
  ConsumerState<GranoFlowApp> createState() => _GranoFlowAppState();
}

class _GranoFlowAppState extends ConsumerState<GranoFlowApp> {
  @override
  void initState() {
    super.initState();
    // 在应用启动后初始化系统托盘（仅桌面平台）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSystemTray();
    });
  }

  Future<void> _initializeSystemTray() async {
    debugPrint('[GranoFlowApp] Starting system tray initialization...');
    // 检测运行平台
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      debugPrint('[GranoFlowApp] Not a desktop platform, skipping system tray initialization');
      return;
    }

    try {
      debugPrint('[GranoFlowApp] Reading system tray service provider...');
      // 读取系统托盘服务并初始化
      final service = await ref.read(systemTrayServiceProvider.future);
      debugPrint('[GranoFlowApp] System tray service obtained, calling init...');
      await service.init();
      debugPrint('[GranoFlowApp] System tray service initialized');

      // 更新初始化状态
      ref.read(systemTrayInitializedProvider.notifier).state = true;
      debugPrint('[GranoFlowApp] System tray initialization completed successfully');
    } catch (error, stackTrace) {
      debugPrint('[GranoFlowApp] Failed to initialize system tray: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferenceLocale = ref
        .watch(appLocaleProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final localeValue = widget.locale ?? preferenceLocale;
    final themeMode = ref
        .watch(themeProvider)
        .maybeWhen(data: (value) => value, orElse: () => ThemeMode.system);
    final fontScaleLevel = ref.watch(fontScaleLevelProvider).maybeWhen(
          data: (value) => value,
          orElse: () => FontScaleConstants.getDefaultLevel(),
        );
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
        // 根据字体大小级别和当前屏幕方向动态计算实际的字体缩放值
        final orientation = MediaQuery.of(context).orientation;
        final actualFontScale = FontScaleConstants.getScaleForLevel(
          orientation,
          fontScaleLevel,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(actualFontScale),
          ),
          child: child!,
        );
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: AppRouter.router,
    );
  }
}
