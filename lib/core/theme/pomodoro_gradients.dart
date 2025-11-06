import 'package:flutter/material.dart';

import '../utils/gradient_composer.dart';
import 'ocean_breeze_color_schemes.dart';

/// 番茄时钟专用渐变定义
///
/// 所有颜色都从 OceanBreezeColorSchemes 引用，不硬编码颜色值
class PomodoroGradients {
  const PomodoroGradients._();

  // ============ Light 模式渐变 ============

  /// 正常状态渐变：番茄红 → 橙色 → 海盐蓝 → 海军蓝
  static const LinearGradient lightNormal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.pomodoroTomatoRed, // 番茄红
      OceanBreezeColorSchemes.pomodoroVibrantOrange, // 活力橙
      OceanBreezeColorSchemes.seaSaltBlue, // 海盐蓝
      OceanBreezeColorSchemes.navyBlue, // 海军蓝
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  /// 完成状态渐变：成功绿 → 薄荷青 → 海盐蓝
  static const LinearGradient lightComplete = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.pomodoroSuccessGreen, // 成功绿
      OceanBreezeColorSchemes.mintCyan, // 薄荷青
      OceanBreezeColorSchemes.seaSaltBlue, // 海盐蓝
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// 暂停状态渐变：灰色调
  static const LinearGradient lightPaused = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.pomodoroPausedLight, // 灰色
      OceanBreezeColorSchemes.pomodoroPausedMedium, // 浅灰
      OceanBreezeColorSchemes.pomodoroPausedLight2, // 更浅灰
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============ Dark 模式渐变 ============

  /// 正常状态渐变：深番茄红 → 深橙 → 湖光青 → 深海军蓝
  static const LinearGradient darkNormal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.pomodoroDeepTomatoRed, // 深番茄红
      OceanBreezeColorSchemes.pomodoroDeepOrange, // 深橙
      OceanBreezeColorSchemes.lakeCyan, // 湖光青
      OceanBreezeColorSchemes.navyBlue, // 深海军蓝
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  /// 完成状态渐变：深绿 → 薄荷青 → 湖光青
  static const LinearGradient darkComplete = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.pomodoroDeepGreen, // 深绿
      OceanBreezeColorSchemes.mintCyan, // 薄荷青
      OceanBreezeColorSchemes.lakeCyan, // 湖光青
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// 暂停状态渐变：深灰色调
  static const LinearGradient darkPaused = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.pomodoroPausedDark, // 深灰
      OceanBreezeColorSchemes.pomodoroPausedDark2, // 中灰
      OceanBreezeColorSchemes.pomodoroPausedDark3, // 浅灰
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============ 工具方法 ============

  /// 根据主题模式和状态获取对应的渐变
  static LinearGradient getGradient({
    required Brightness brightness,
    required PomodoroState state,
  }) {
    final isLight = brightness == Brightness.light;
    switch (state) {
      case PomodoroState.normal:
        return isLight ? lightNormal : darkNormal;
      case PomodoroState.complete:
        return isLight ? lightComplete : darkComplete;
      case PomodoroState.paused:
        return isLight ? lightPaused : darkPaused;
    }
  }

  /// 复合海浪背景配置：包含多层渐变、纹理、粒子
  static CompositeWaveGradient getWaveGradient({
    required Brightness brightness,
    required PomodoroState state,
  }) {
    final isLight = brightness == Brightness.light;
    switch (state) {
      case PomodoroState.normal:
        return isLight ? _lightWaveNormal : _darkWaveNormal;
      case PomodoroState.complete:
        return GradientComposer.singleLinear(
          isLight ? lightComplete : darkComplete,
        );
      case PomodoroState.paused:
        return GradientComposer.singleLinear(
          isLight ? lightPaused : darkPaused,
        );
    }
  }

  static final CompositeWaveGradient _lightWaveNormal = CompositeWaveGradient(
    fallback: lightNormal,
    layers: [
      WaveLinearGradientLayer(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          OceanBreezeColorSchemes.skyWhite,
          OceanBreezeColorSchemes.seaSaltBlue,
          OceanBreezeColorSchemes.mintCyan,
          OceanBreezeColorSchemes.lakeCyan,
        ],
        stops: const [0.0, 0.3, 0.65, 1.0],
      ),
      WaveRadialGradientLayer(
        center: const Alignment(0.0, -0.6),
        radius: 1.2,
        colors: [
          OceanBreezeColorSchemes.pomodoroTomatoRed,
          OceanBreezeColorSchemes.pomodoroVibrantOrange,
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 1.0],
        blendMode: BlendMode.screen,
      ),
      WaveLinearGradientLayer(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          OceanBreezeColorSchemes.lightSeaSalt.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      WaveTextureLayer(
        asset: 'assets/textures/ocean_foam.png',
        opacity: 0.12,
        scale: 1.1,
      ),
    ],
  );

  static final CompositeWaveGradient _darkWaveNormal = CompositeWaveGradient(
    fallback: darkNormal,
    layers: [
      WaveLinearGradientLayer(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [
          OceanBreezeColorSchemes.darkNight,
          OceanBreezeColorSchemes.floatingWater,
          OceanBreezeColorSchemes.navyBlue,
        ],
        stops: const [0.0, 0.55, 1.0],
      ),
      WaveRadialGradientLayer(
        center: const Alignment(0.2, -0.4),
        radius: 1.0,
        colors: [
          OceanBreezeColorSchemes.pomodoroDeepTomatoRed.withValues(alpha: 0.55),
          OceanBreezeColorSchemes.pomodoroDeepOrange.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
        blendMode: BlendMode.plus,
      ),
      WaveLinearGradientLayer(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.transparent,
          OceanBreezeColorSchemes.mintCyan.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ),
      WaveTextureLayer(
        asset: 'assets/textures/ocean_foam.png',
        opacity: 0.08,
        scale: 1.05,
        blendMode: BlendMode.screen,
      ),
      WaveParticleLayer(
        style: WaveParticleStyle.starGlint,
        color: OceanBreezeColorSchemes.auroraBlue.withValues(alpha: 0.25),
        density: 0.3,
        opacity: 0.9,
      ),
    ],
  );
}

/// 番茄时钟状态枚举
enum PomodoroState {
  /// 正常计时状态
  normal,

  /// 完成状态
  complete,

  /// 暂停状态
  paused,
}
