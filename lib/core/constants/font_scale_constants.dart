import 'package:flutter/material.dart';

/// 字体大小缩放常量
///
/// 根据技术规范定义，统一管理所有字体大小选项。
/// 竖屏和横屏使用不同的字体大小值，以适应不同的屏幕空间。
class FontScaleConstants {
  const FontScaleConstants._();

  /// 竖屏字体大小选项
  /// 
  /// 对应：小、中、大、超大
  /// Values: Small, Medium, Large, XLarge
  static const List<double> portraitScales = [0.75, 0.85, 1.0, 1.125];

  /// 横屏字体大小选项
  /// 
  /// 对应：小、中、大、超大
  /// Values: Small, Medium, Large, XLarge
  static const List<double> landscapeScales = [0.85, 1.0, 1.125, 1.25];

  /// 获取指定方向的字体大小选项
  static List<double> getScalesForOrientation(Orientation orientation) {
    return orientation == Orientation.portrait
        ? portraitScales
        : landscapeScales;
  }

  /// 竖屏的"中"字体大小
  /// 
  /// 这是默认字体大小，因为大多数应用使用竖屏模式
  static const double defaultFontScale = 0.85;

  /// 横屏的"中"字体大小
  static const double landscapeMediumFontScale = 1.0;

  /// 竖屏的"中"字体大小
  static const double portraitMediumFontScale = 0.85;

  /// 根据屏幕方向获取"中"字体大小
  static double getMediumFontScale(Orientation orientation) {
    return orientation == Orientation.portrait
        ? portraitMediumFontScale
        : landscapeMediumFontScale;
  }
}

