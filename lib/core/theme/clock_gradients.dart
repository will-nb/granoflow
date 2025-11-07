import 'package:flutter/material.dart';

import '../utils/gradient_composer.dart';
import 'ocean_breeze_color_schemes.dart';

/// 计时器专用渐变定义
///
/// 所有颜色都从 OceanBreezeColorSchemes 引用，不硬编码颜色值
class ClockGradients {
  const ClockGradients._();

  // ============ Light 模式渐变 ============

  /// 正常状态渐变：主红色 → 橙色 → 海盐蓝 → 海军蓝
  static const LinearGradient lightNormal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.clockPrimaryRed, // 主红色
      OceanBreezeColorSchemes.clockPrimaryOrange, // 主橙色
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
      OceanBreezeColorSchemes.clockSuccessGreen, // 成功绿
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
      OceanBreezeColorSchemes.clockPausedLight, // 灰色
      OceanBreezeColorSchemes.clockPausedMedium, // 浅灰
      OceanBreezeColorSchemes.clockPausedLight2, // 更浅灰
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============ Dark 模式渐变 ============

  /// 正常状态渐变：深主红色 → 深橙 → 湖光青 → 深海军蓝
  static const LinearGradient darkNormal = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.clockDeepRed, // 深红色
      OceanBreezeColorSchemes.clockDeepOrange, // 深橙
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
      OceanBreezeColorSchemes.clockDeepGreen, // 深绿
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
      OceanBreezeColorSchemes.clockPausedDark, // 深灰
      OceanBreezeColorSchemes.clockPausedDark2, // 中灰
      OceanBreezeColorSchemes.clockPausedDark3, // 浅灰
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ============ 工具方法 ============

  /// 根据主题模式和状态获取对应的渐变
  static LinearGradient getGradient({
    required Brightness brightness,
    required ClockState state,
  }) {
    final isLight = brightness == Brightness.light;
    switch (state) {
      case ClockState.normal:
        return isLight ? lightNormal : darkNormal;
      case ClockState.complete:
        return isLight ? lightComplete : darkComplete;
      case ClockState.paused:
        return isLight ? lightPaused : darkPaused;
    }
  }

  /// 复合海浪背景配置：包含多层渐变、纹理、粒子
  static CompositeWaveGradient getWaveGradient({
    required Brightness brightness,
    required ClockState state,
  }) {
    final isLight = brightness == Brightness.light;
    switch (state) {
      case ClockState.normal:
        return isLight ? _lightWaveNormal : _darkWaveNormal;
      case ClockState.complete:
        return GradientComposer.singleLinear(
          isLight ? lightComplete : darkComplete,
        );
      case ClockState.paused:
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
          OceanBreezeColorSchemes.clockPrimaryRed.withValues(alpha: 0.3),
          OceanBreezeColorSchemes.clockPrimaryOrange.withValues(alpha: 0.2),
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
          OceanBreezeColorSchemes.lightSeaSalt.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
      WaveTextureLayer(
        asset: 'assets/textures/ocean_foam.png',
        opacity: 0.06,
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
          OceanBreezeColorSchemes.clockDeepRed.withValues(alpha: 0.3),
          OceanBreezeColorSchemes.clockDeepOrange.withValues(alpha: 0.2),
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
          OceanBreezeColorSchemes.mintCyan.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ),
      WaveTextureLayer(
        asset: 'assets/textures/ocean_foam.png',
        opacity: 0.04,
        scale: 1.05,
        blendMode: BlendMode.screen,
      ),
      WaveParticleLayer(
        style: WaveParticleStyle.starGlint,
        color: OceanBreezeColorSchemes.auroraBlue.withValues(alpha: 0.15),
        density: 0.3,
        opacity: 0.9,
      ),
    ],
  );
}

/// 计时器状态枚举
enum ClockState {
  /// 正常计时状态
  normal,

  /// 完成状态
  complete,

  /// 暂停状态
  paused,
}
