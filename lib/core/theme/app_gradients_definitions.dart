import 'package:flutter/material.dart';

import 'ocean_breeze_color_schemes.dart';

/// 渐变定义常量
/// 
/// 包含所有预定义的渐变
class AppGradientsDefinitions {
  const AppGradientsDefinitions._();

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
}

