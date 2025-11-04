import 'package:flutter/material.dart';

/// 拖拽主题扩展
/// 
/// 管理拖拽相关颜色，集成到 Flutter 主题系统
/// 支持间隔线方案：使用间隔线替代让位动画提供视觉反馈
@immutable
class DragTheme extends ThemeExtension<DragTheme> {
  const DragTheme({
    required this.hoverBackgroundBetween,
    required this.hoverBackgroundSection,
    required this.shadowColor,
    required this.insertionLineColor,
    required this.insertionLineShadowAlpha,
  });

  final Color hoverBackgroundBetween;
  final Color hoverBackgroundSection;
  final Color shadowColor;
  final Color insertionLineColor; // 间隔线颜色（使用主题主色）
  final double insertionLineShadowAlpha; // 间隔线阴影透明度（浅色主题 0.3，深色主题 0.4）

  static DragTheme of(BuildContext context) {
    return Theme.of(context).extension<DragTheme>() ?? _defaultLight(context);
  }

  @override
  DragTheme copyWith({
    Color? hoverBackgroundBetween,
    Color? hoverBackgroundSection,
    Color? shadowColor,
    Color? insertionLineColor,
    double? insertionLineShadowAlpha,
  }) {
    return DragTheme(
      hoverBackgroundBetween: hoverBackgroundBetween ?? this.hoverBackgroundBetween,
      hoverBackgroundSection: hoverBackgroundSection ?? this.hoverBackgroundSection,
      shadowColor: shadowColor ?? this.shadowColor,
      insertionLineColor: insertionLineColor ?? this.insertionLineColor,
      insertionLineShadowAlpha: insertionLineShadowAlpha ?? this.insertionLineShadowAlpha,
    );
  }

  @override
  DragTheme lerp(ThemeExtension<DragTheme>? other, double t) {
    if (other is! DragTheme) {
      return this;
    }
    return DragTheme(
      hoverBackgroundBetween: Color.lerp(hoverBackgroundBetween, other.hoverBackgroundBetween, t)!,
      hoverBackgroundSection: Color.lerp(hoverBackgroundSection, other.hoverBackgroundSection, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
      insertionLineColor: Color.lerp(insertionLineColor, other.insertionLineColor, t)!,
      insertionLineShadowAlpha: (insertionLineShadowAlpha * (1 - t) + other.insertionLineShadowAlpha * t),
    );
  }

  static DragTheme _defaultLight(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DragTheme(
      hoverBackgroundBetween: colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
      hoverBackgroundSection: colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
      shadowColor: colorScheme.shadow,
      insertionLineColor: colorScheme.primary, // 使用主题主色作为间隔线颜色
      insertionLineShadowAlpha: 0.3, // 浅色主题使用 0.3 透明度
    );
  }

  // 从当前 ColorScheme 动态生成 DragTheme，避免硬编码
  // 设计原则：
  // 1. 使用间隔线方案，替代移动让位动画
  // 2. 间隔线使用主题主色，带轻微阴影增强视觉层次
  // 3. hover 背景色使用透明，间隔线本身已足够明显
  // 4. 对色盲友好（使用灰度对比而非色相）
  static DragTheme fromScheme(ColorScheme scheme, Brightness brightness) {
    return DragTheme(
      hoverBackgroundBetween: Colors.transparent,
      hoverBackgroundSection: Colors.transparent,
      shadowColor: scheme.shadow,
      insertionLineColor: scheme.primary, // 使用主题主色
      insertionLineShadowAlpha: brightness == Brightness.light ? 0.3 : 0.4, // 浅色 0.3，深色 0.4
    );
  }
}
