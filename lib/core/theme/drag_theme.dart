import 'package:flutter/material.dart';

/// 拖拽主题扩展
/// 
/// 管理拖拽相关颜色，集成到 Flutter 主题系统
@immutable
class DragTheme extends ThemeExtension<DragTheme> {
  const DragTheme({
    required this.insertionLineBetweenColor,
    required this.insertionLineSectionColor,
    required this.hoverBackgroundBetween,
    required this.hoverBackgroundSection,
    required this.shadowColor,
  });

  final Color insertionLineBetweenColor;
  final Color insertionLineSectionColor;
  final Color hoverBackgroundBetween;
  final Color hoverBackgroundSection;
  final Color shadowColor;

  static DragTheme of(BuildContext context) {
    return Theme.of(context).extension<DragTheme>() ?? _defaultLight(context);
  }

  @override
  DragTheme copyWith({
    Color? insertionLineBetweenColor,
    Color? insertionLineSectionColor,
    Color? hoverBackgroundBetween,
    Color? hoverBackgroundSection,
    Color? shadowColor,
  }) {
    return DragTheme(
      insertionLineBetweenColor: insertionLineBetweenColor ?? this.insertionLineBetweenColor,
      insertionLineSectionColor: insertionLineSectionColor ?? this.insertionLineSectionColor,
      hoverBackgroundBetween: hoverBackgroundBetween ?? this.hoverBackgroundBetween,
      hoverBackgroundSection: hoverBackgroundSection ?? this.hoverBackgroundSection,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  DragTheme lerp(ThemeExtension<DragTheme>? other, double t) {
    if (other is! DragTheme) {
      return this;
    }
    return DragTheme(
      insertionLineBetweenColor: Color.lerp(insertionLineBetweenColor, other.insertionLineBetweenColor, t)!,
      insertionLineSectionColor: Color.lerp(insertionLineSectionColor, other.insertionLineSectionColor, t)!,
      hoverBackgroundBetween: Color.lerp(hoverBackgroundBetween, other.hoverBackgroundBetween, t)!,
      hoverBackgroundSection: Color.lerp(hoverBackgroundSection, other.hoverBackgroundSection, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }

  static DragTheme _defaultLight(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DragTheme(
      insertionLineBetweenColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.18),
      insertionLineSectionColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.22),
      hoverBackgroundBetween: colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
      hoverBackgroundSection: colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
      shadowColor: colorScheme.shadow,
    );
  }

  // 从当前 ColorScheme 动态生成 DragTheme，避免硬编码
  // 设计原则：
  // 1. 在白色 Card 背景上清晰可见
  // 2. 对色盲友好（使用灰度对比而非色相）
  // 3. 柔和低调，不刺眼
  static DragTheme fromScheme(ColorScheme scheme, Brightness brightness) {
    // Light 模式：在白色 Card 上使用中等灰度（不太深不太浅）
    // Dark 模式：在深色 Card 上使用稍浅的灰色
    final Color insertionLine;
    if (brightness == Brightness.light) {
      // Light: 使用 onSurface 的 28% 透明度，柔和的中灰色
      insertionLine = scheme.onSurface.withValues(alpha: 0.28);
    } else {
      // Dark: 使用 onSurface 的 40% 透明度，确保在深色背景上可见
      insertionLine = scheme.onSurface.withValues(alpha: 0.40);
    }
    
    return DragTheme(
      insertionLineBetweenColor: insertionLine,
      insertionLineSectionColor: insertionLine,
      hoverBackgroundBetween: Colors.transparent,
      hoverBackgroundSection: Colors.transparent,
      shadowColor: scheme.shadow,
    );
  }
}
