import 'package:flutter/material.dart';

import 'app_gradients_definitions.dart';
import 'app_gradients_extension_lerp.dart';

/// 渐变方向枚举
enum GradientDirection {
  vertical,
  horizontal,
  diagonal45,
  diagonal135,
  radial,
}

/// 渐变类型枚举
enum GradientType {
  primary,
  secondary,
  accent,
  success,
  warning,
  error,
  info,
}

/// Ocean Breeze 渐变背景系统
/// 基于清爽水蓝配色方案的多层次渐变定义
class AppGradients {
  const AppGradients._();

  // 渐变定义委托给 AppGradientsDefinitions
  static const LinearGradient seaSaltSky = AppGradientsDefinitions.seaSaltSky;
  static const LinearGradient mintLake = AppGradientsDefinitions.mintLake;
  static const LinearGradient skyNavy = AppGradientsDefinitions.skyNavy;
  static const RadialGradient waterRipple = AppGradientsDefinitions.waterRipple;
  static const LinearGradient oceanDepth = AppGradientsDefinitions.oceanDepth;
  static const LinearGradient skyEmbrace = AppGradientsDefinitions.skyEmbrace;
  static const LinearGradient skyLight = AppGradientsDefinitions.skyLight;
  static const LinearGradient deepSeaGlow = AppGradientsDefinitions.deepSeaGlow;
  static const LinearGradient success = AppGradientsDefinitions.success;
  static const LinearGradient warning = AppGradientsDefinitions.warning;
  static const LinearGradient error = AppGradientsDefinitions.error;
  static const LinearGradient info = AppGradientsDefinitions.info;

  /// 根据类型获取渐变
  static Gradient getGradient(GradientType type) {
    switch (type) {
      case GradientType.primary:
        return seaSaltSky;
      case GradientType.secondary:
        return mintLake;
      case GradientType.accent:
        return skyNavy;
      case GradientType.success:
        return success;
      case GradientType.warning:
        return warning;
      case GradientType.error:
        return error;
      case GradientType.info:
        return info;
    }
  }

  /// 根据方向创建自定义渐变
  static LinearGradient createLinearGradient({
    required List<Color> colors,
    required GradientDirection direction,
    List<double>? stops,
  }) {
    late AlignmentGeometry begin;
    late AlignmentGeometry end;
    
    switch (direction) {
      case GradientDirection.vertical:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case GradientDirection.horizontal:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
      case GradientDirection.diagonal45:
        begin = Alignment.topLeft;
        end = Alignment.bottomRight;
        break;
      case GradientDirection.diagonal135:
        begin = Alignment.topRight;
        end = Alignment.bottomLeft;
        break;
      case GradientDirection.radial:
        throw ArgumentError('Use RadialGradient for radial gradients');
    }

    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    );
  }

  /// 创建径向渐变
  static RadialGradient createRadialGradient({
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double radius = 1.0,
    List<double>? stops,
  }) {
    return RadialGradient(
      center: center,
      radius: radius,
      colors: colors,
      stops: stops,
    );
  }
}

/// 渐变背景工具类
class GradientHelper {
  const GradientHelper._();

  /// 检查渐变是否适合深色主题
  static bool isSuitableForDarkTheme(Gradient gradient) {
    if (gradient is LinearGradient) {
      return gradient.colors.any((color) => 
        color.computeLuminance() < 0.5);
    }
    return false;
  }

  /// 获取渐变的平均亮度
  static double getAverageLuminance(Gradient gradient) {
    if (gradient is LinearGradient) {
      double totalLuminance = 0;
      for (final color in gradient.colors) {
        totalLuminance += color.computeLuminance();
      }
      return totalLuminance / gradient.colors.length;
    }
    return 0.5;
  }

  /// 根据亮度调整渐变颜色
  static LinearGradient adjustBrightness(
    LinearGradient gradient,
    double factor,
  ) {
    final adjustedColors = gradient.colors.map((color) {
      return Color.fromARGB(
        (color.a * 255.0).round().toInt() & 0xff,
        ((color.r * 255.0).round() * factor).clamp(0, 255).toInt() & 0xff,
        ((color.g * 255.0).round() * factor).clamp(0, 255).toInt() & 0xff,
        ((color.b * 255.0).round() * factor).clamp(0, 255).toInt() & 0xff,
      );
    }).toList();

    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: adjustedColors,
      stops: gradient.stops,
    );
  }
}

/// 渐变主题扩展
/// 为主题系统提供渐变支持
@immutable
class AppGradientsExtension extends ThemeExtension<AppGradientsExtension> {
  const AppGradientsExtension({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.pageBackground,
    required this.cardBackground,
  });

  final Gradient primary;
  final Gradient secondary;
  final Gradient accent;
  final Gradient success;
  final Gradient warning;
  final Gradient error;
  final Gradient info;
  final Gradient pageBackground;
  final Gradient cardBackground;

  /// 浅色主题渐变
  static const AppGradientsExtension light = AppGradientsExtension(
    primary: AppGradients.seaSaltSky,
    secondary: AppGradients.mintLake,
    accent: AppGradients.skyNavy,
    success: AppGradients.success,
    warning: AppGradients.warning,
    error: AppGradients.error,
    info: AppGradients.info,
    pageBackground: AppGradients.skyLight, // 使用更浅的渐变，提高对比度
    cardBackground: AppGradients.skyNavy,
  );

  /// 深色主题渐变 - 深海流光
  static const AppGradientsExtension dark = AppGradientsExtension(
    primary: AppGradients.oceanDepth,
    secondary: AppGradients.mintLake,
    accent: AppGradients.skyNavy,
    success: AppGradients.success,
    warning: AppGradients.warning,
    error: AppGradients.error,
    info: AppGradients.info,
    pageBackground: AppGradients.deepSeaGlow,
    cardBackground: AppGradients.skyNavy,
  );

  @override
  AppGradientsExtension copyWith({
    Gradient? primary,
    Gradient? secondary,
    Gradient? accent,
    Gradient? success,
    Gradient? warning,
    Gradient? error,
    Gradient? info,
    Gradient? pageBackground,
    Gradient? cardBackground,
  }) {
    return AppGradientsExtension(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      pageBackground: pageBackground ?? this.pageBackground,
      cardBackground: cardBackground ?? this.cardBackground,
    );
  }

  @override
  AppGradientsExtension lerp(ThemeExtension<AppGradientsExtension>? other, double t) {
    if (other is! AppGradientsExtension) {
      return this;
    }
    return AppGradientsExtensionLerp.lerp(this, other, t);
  }
}

/// 渐变主题扩展工具
extension AppGradientsTheme on BuildContext {
  AppGradientsExtension get gradients {
    final gradients = Theme.of(this).extension<AppGradientsExtension>();
    if (gradients == null) {
      throw StateError('AppGradientsExtension not found on Theme');
    }
    return gradients;
  }
}
