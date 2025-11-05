import 'package:flutter/material.dart';

/// 日历主题令牌（Calendar Tokens）
/// 
/// 统一管理日历组件相关的尺寸常量，避免硬编码
/// 遵循 Material Design 3 设计规范
@immutable
class AppCalendarTokens extends ThemeExtension<AppCalendarTokens> {
  const AppCalendarTokens({
    required this.cellMinHeight,
    required this.cellMaxHeight,
    required this.cellDefaultAspectRatio,
    required this.cellSpacing,
    required this.cellHorizontalPadding,
  });

  /// 日历单元格最小高度
  final double cellMinHeight;
  
  /// 日历单元格最大高度
  final double cellMaxHeight;
  
  /// 日历单元格默认宽高比（宽度/高度）
  final double cellDefaultAspectRatio;
  
  /// 日历单元格之间的间距
  final double cellSpacing;
  
  /// 日历网格水平内边距
  final double cellHorizontalPadding;

  /// 浅色主题日历令牌
  static const AppCalendarTokens light = AppCalendarTokens(
    cellMinHeight: 40.0,
    cellMaxHeight: 60.0,
    cellDefaultAspectRatio: 0.85,
    cellSpacing: 2.0,
    cellHorizontalPadding: 12.0,
  );

  /// 深色主题日历令牌（与浅色主题值相同）
  static const AppCalendarTokens dark = AppCalendarTokens(
    cellMinHeight: 40.0,
    cellMaxHeight: 60.0,
    cellDefaultAspectRatio: 0.85,
    cellSpacing: 2.0,
    cellHorizontalPadding: 12.0,
  );

  @override
  AppCalendarTokens copyWith({
    double? cellMinHeight,
    double? cellMaxHeight,
    double? cellDefaultAspectRatio,
    double? cellSpacing,
    double? cellHorizontalPadding,
  }) {
    return AppCalendarTokens(
      cellMinHeight: cellMinHeight ?? this.cellMinHeight,
      cellMaxHeight: cellMaxHeight ?? this.cellMaxHeight,
      cellDefaultAspectRatio: cellDefaultAspectRatio ?? this.cellDefaultAspectRatio,
      cellSpacing: cellSpacing ?? this.cellSpacing,
      cellHorizontalPadding: cellHorizontalPadding ?? this.cellHorizontalPadding,
    );
  }

  @override
  AppCalendarTokens lerp(ThemeExtension<AppCalendarTokens>? other, double t) {
    if (other is! AppCalendarTokens) {
      return this;
    }
    return AppCalendarTokens(
      cellMinHeight: (cellMinHeight * (1 - t) + other.cellMinHeight * t),
      cellMaxHeight: (cellMaxHeight * (1 - t) + other.cellMaxHeight * t),
      cellDefaultAspectRatio: (cellDefaultAspectRatio * (1 - t) + other.cellDefaultAspectRatio * t),
      cellSpacing: (cellSpacing * (1 - t) + other.cellSpacing * t),
      cellHorizontalPadding: (cellHorizontalPadding * (1 - t) + other.cellHorizontalPadding * t),
    );
  }
}

/// 便捷的扩展方法，用于从 BuildContext 获取 AppCalendarTokens
extension AppThemeCalendar on BuildContext {
  AppCalendarTokens get calendarTokens {
    final tokens = Theme.of(this).extension<AppCalendarTokens>();
    if (tokens == null) {
      throw StateError('AppCalendarTokens not found on Theme');
    }
    return tokens;
  }
}

