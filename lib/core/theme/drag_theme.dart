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
      insertionLineBetweenColor: colorScheme.secondary,
      insertionLineSectionColor: colorScheme.tertiary,
      hoverBackgroundBetween: colorScheme.secondary.withValues(alpha: 0.1),
      hoverBackgroundSection: colorScheme.tertiary.withValues(alpha: 0.1),
      shadowColor: colorScheme.shadow,
    );
  }


  static const DragTheme light = DragTheme(
    insertionLineBetweenColor: Color(0xFF6750A4), // secondary
    insertionLineSectionColor: Color(0xFF7D5260), // tertiary
    hoverBackgroundBetween: Color(0x1A6750A4), // secondary with 10% alpha
    hoverBackgroundSection: Color(0x1A7D5260), // tertiary with 10% alpha
    shadowColor: Color(0xFF000000),
  );

  static const DragTheme dark = DragTheme(
    insertionLineBetweenColor: Color(0xFFD0BCFF), // secondary
    insertionLineSectionColor: Color(0xFFFFB1C8), // tertiary
    hoverBackgroundBetween: Color(0x1AD0BCFF), // secondary with 10% alpha
    hoverBackgroundSection: Color(0x1AFFB1C8), // tertiary with 10% alpha
    shadowColor: Color(0xFF000000),
  );
}
