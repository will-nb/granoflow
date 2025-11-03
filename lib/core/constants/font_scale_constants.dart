import 'package:flutter/material.dart';

import 'font_scale_level.dart';

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
  /// @deprecated 使用 getDefaultLevel() 和 getScaleForLevel() 代替
  static const double defaultFontScale = 0.85;

  /// 横屏的"中"字体大小
  static const double landscapeMediumFontScale = 1.0;

  /// 竖屏的"中"字体大小
  static const double portraitMediumFontScale = 0.85;

  /// 根据屏幕方向获取"中"字体大小
  /// @deprecated 使用 getScaleForLevel() 代替
  static double getMediumFontScale(Orientation orientation) {
    return orientation == Orientation.portrait
        ? portraitMediumFontScale
        : landscapeMediumFontScale;
  }

  /// 获取默认字体大小级别
  /// 
  /// 返回 FontScaleLevel.medium
  static FontScaleLevel getDefaultLevel() {
    return FontScaleLevel.medium;
  }

  /// 根据屏幕方向和字体大小级别获取实际的缩放数值
  /// 
  /// [orientation] 屏幕方向（竖屏或横屏）
  /// [level] 字体大小级别（small, medium, large, xlarge）
  /// 
  /// 返回对应的字体缩放数值。例如：
  /// - 竖屏 medium: 0.85
  /// - 横屏 medium: 1.0
  static double getScaleForLevel(
    Orientation orientation,
    FontScaleLevel level,
  ) {
    final scales = getScalesForOrientation(orientation);
    final index = FontScaleLevel.values.indexOf(level);
    // 确保索引在有效范围内
    if (index < 0 || index >= scales.length) {
      // 如果索引无效，返回"中"对应的值
      return orientation == Orientation.portrait
          ? portraitMediumFontScale
          : landscapeMediumFontScale;
    }
    return scales[index];
  }
}

