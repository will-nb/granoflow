import 'package:flutter/material.dart';

import 'ocean_breeze_color_schemes.dart';

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

  /// 海盐蓝天际渐变 - 主页面背景
  static const LinearGradient seaSaltSky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.seaSaltBlue,
      OceanBreezeColorSchemes.skyWhite,
    ],
  );

  /// 薄荷青湖光渐变 - 按钮和强调区域
  static const LinearGradient mintLake = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      OceanBreezeColorSchemes.mintCyan,
      OceanBreezeColorSchemes.lakeCyan,
    ],
  );

  /// 天际白海军渐变 - 内容区域背景
  static const LinearGradient skyNavy = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.skyWhite,
      OceanBreezeColorSchemes.navyBlue,
    ],
  );

  /// 水波涟漪渐变 - 特殊页面背景
  static const RadialGradient waterRipple = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [
      OceanBreezeColorSchemes.seaSaltBlue,
      OceanBreezeColorSchemes.mintCyan,
      OceanBreezeColorSchemes.skyWhite,
    ],
    stops: [0.0, 0.6, 1.0],
  );

  /// 海洋深度渐变 - 深色主题背景
  static const LinearGradient oceanDepth = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.mintCyan,
      OceanBreezeColorSchemes.seaSaltBlue,
      OceanBreezeColorSchemes.lakeCyan,
      OceanBreezeColorSchemes.navyBlue,
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  /// 天际拥抱渐变 - 两端浅色中间深色，自然衔接导航栏
  static const LinearGradient skyEmbrace = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.skyWhite,
      OceanBreezeColorSchemes.seaSaltBlue,
      OceanBreezeColorSchemes.skyWhite,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// 轻盈天际渐变 - 浅色柔和版，为按钮留出视觉空间
  static const LinearGradient skyLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.veryLightSky,
      OceanBreezeColorSchemes.lightSeaSalt,
      OceanBreezeColorSchemes.veryLightSky,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// 深海流光渐变 - 深色主题背景光晕
  static const LinearGradient deepSeaGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.navyBlue,      // 顶部：海军蓝（与 AppBar 完美衔接）
      OceanBreezeColorSchemes.floatingWater, // 中间：浮层水色（视觉焦点）
      OceanBreezeColorSchemes.navyBlue,      // 底部：海军蓝（与 BottomNavigationBar 完美衔接）
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// 成功状态渐变
  static const LinearGradient success = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      OceanBreezeColorSchemes.softGreen,
      OceanBreezeColorSchemes.mintCyan,
    ],
  );

  /// 警告状态渐变
  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      OceanBreezeColorSchemes.warmYellow,
      OceanBreezeColorSchemes.skyWhite,
    ],
  );

  /// 错误状态渐变
  static const LinearGradient error = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      OceanBreezeColorSchemes.softPink,
      OceanBreezeColorSchemes.skyWhite,
    ],
  );

  /// 信息状态渐变
  static const LinearGradient info = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      OceanBreezeColorSchemes.lightBlueGray,
      OceanBreezeColorSchemes.mintCyan,
    ],
  );

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
    return AppGradientsExtension(
      primary: LinearGradient.lerp(primary as LinearGradient, other.primary as LinearGradient, t) ?? primary,
      secondary: LinearGradient.lerp(secondary as LinearGradient, other.secondary as LinearGradient, t) ?? secondary,
      accent: LinearGradient.lerp(accent as LinearGradient, other.accent as LinearGradient, t) ?? accent,
      success: LinearGradient.lerp(success as LinearGradient, other.success as LinearGradient, t) ?? success,
      warning: LinearGradient.lerp(warning as LinearGradient, other.warning as LinearGradient, t) ?? warning,
      error: LinearGradient.lerp(error as LinearGradient, other.error as LinearGradient, t) ?? error,
      info: LinearGradient.lerp(info as LinearGradient, other.info as LinearGradient, t) ?? info,
      pageBackground: LinearGradient.lerp(pageBackground as LinearGradient, other.pageBackground as LinearGradient, t) ?? pageBackground,
      cardBackground: LinearGradient.lerp(cardBackground as LinearGradient, other.cardBackground as LinearGradient, t) ?? cardBackground,
    );
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
