import 'package:flutter/material.dart';

import 'app_gradients.dart';

/// AppGradientsExtension lerp 方法辅助类
/// 
/// 包含渐变插值的辅助方法
class AppGradientsExtensionLerp {
  /// 对两个渐变进行插值
  static LinearGradient? lerpGradient(
    LinearGradient? a,
    LinearGradient? b,
    double t,
  ) {
    if (a == null || b == null) {
      return a ?? b;
    }
    return LinearGradient.lerp(a, b, t);
  }

  /// 对 AppGradientsExtension 进行插值
  static AppGradientsExtension lerp(
    AppGradientsExtension? a,
    AppGradientsExtension? b,
    double t,
  ) {
    if (a == null || b == null) {
      return a ?? b ?? AppGradientsExtension.light;
    }

    return AppGradientsExtension(
      primary: lerpGradient(
        a.primary as LinearGradient,
        b.primary as LinearGradient,
        t,
      ) ?? a.primary as LinearGradient,
      secondary: lerpGradient(
        a.secondary as LinearGradient,
        b.secondary as LinearGradient,
        t,
      ) ?? a.secondary as LinearGradient,
      accent: lerpGradient(
        a.accent as LinearGradient,
        b.accent as LinearGradient,
        t,
      ) ?? a.accent as LinearGradient,
      success: lerpGradient(
        a.success as LinearGradient,
        b.success as LinearGradient,
        t,
      ) ?? a.success as LinearGradient,
      warning: lerpGradient(
        a.warning as LinearGradient,
        b.warning as LinearGradient,
        t,
      ) ?? a.warning as LinearGradient,
      error: lerpGradient(
        a.error as LinearGradient,
        b.error as LinearGradient,
        t,
      ) ?? a.error as LinearGradient,
      info: lerpGradient(
        a.info as LinearGradient,
        b.info as LinearGradient,
        t,
      ) ?? a.info as LinearGradient,
      pageBackground: lerpGradient(
        a.pageBackground as LinearGradient,
        b.pageBackground as LinearGradient,
        t,
      ) ?? a.pageBackground as LinearGradient,
      cardBackground: lerpGradient(
        a.cardBackground as LinearGradient,
        b.cardBackground as LinearGradient,
        t,
      ) ?? a.cardBackground as LinearGradient,
    );
  }
}

