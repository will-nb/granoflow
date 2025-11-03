import 'package:flutter/material.dart';

/// 拖拽主题扩展
/// 
/// 管理拖拽相关颜色，集成到 Flutter 主题系统
/// 注意：不再支持插入线，拖拽排序只使用移动让位动画
@immutable
class DragTheme extends ThemeExtension<DragTheme> {
  const DragTheme({
    required this.hoverBackgroundBetween,
    required this.hoverBackgroundSection,
    required this.shadowColor,
  });

  final Color hoverBackgroundBetween;
  final Color hoverBackgroundSection;
  final Color shadowColor;

  static DragTheme of(BuildContext context) {
    return Theme.of(context).extension<DragTheme>() ?? _defaultLight(context);
  }

  @override
  DragTheme copyWith({
    Color? hoverBackgroundBetween,
    Color? hoverBackgroundSection,
    Color? shadowColor,
  }) {
    return DragTheme(
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
      hoverBackgroundBetween: Color.lerp(hoverBackgroundBetween, other.hoverBackgroundBetween, t)!,
      hoverBackgroundSection: Color.lerp(hoverBackgroundSection, other.hoverBackgroundSection, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }

  static DragTheme _defaultLight(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DragTheme(
      hoverBackgroundBetween: colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
      hoverBackgroundSection: colorScheme.onSurfaceVariant.withValues(alpha: 0.06),
      shadowColor: colorScheme.shadow,
    );
  }

  // 从当前 ColorScheme 动态生成 DragTheme，避免硬编码
  // 设计原则：
  // 1. 只支持移动让位动画，不渲染插入线
  // 2. hover 背景色使用透明，让位动画本身已足够明显
  // 3. 对色盲友好（使用灰度对比而非色相）
  static DragTheme fromScheme(ColorScheme scheme, Brightness brightness) {
    return DragTheme(
      hoverBackgroundBetween: Colors.transparent,
      hoverBackgroundSection: Colors.transparent,
      shadowColor: scheme.shadow,
    );
  }
}
