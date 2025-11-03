import 'package:flutter/material.dart';

/// 应用间距令牌（Spacing Tokens）
/// 
/// 统一管理应用中的间距常量，避免硬编码
/// 遵循 Material Design 3 的 8dp 网格系统
@immutable
class AppSpacingTokens extends ThemeExtension<AppSpacingTokens> {
  const AppSpacingTokens({
    required this.taskTileVerticalPadding,
    required this.taskTileHorizontalPadding,
    required this.cardVerticalPadding,
    required this.cardHorizontalPadding,
    required this.sectionInternalSpacing,
  });

  /// 任务卡片垂直内边距
  final double taskTileVerticalPadding;
  
  /// 任务卡片水平内边距
  final double taskTileHorizontalPadding;
  
  /// 卡片垂直内边距
  final double cardVerticalPadding;
  
  /// 卡片水平内边距
  final double cardHorizontalPadding;
  
  /// 区域内部间距（如 section panel 内部标题和列表之间的间距）
  final double sectionInternalSpacing;

  /// 浅色主题间距令牌（与深色主题值相同）
  static const AppSpacingTokens light = AppSpacingTokens(
    taskTileVerticalPadding: 8.0,
    taskTileHorizontalPadding: 16.0,
    cardVerticalPadding: 8.0,
    cardHorizontalPadding: 16.0,
    sectionInternalSpacing: 8.0,
  );

  /// 深色主题间距令牌（与浅色主题值相同）
  static const AppSpacingTokens dark = AppSpacingTokens(
    taskTileVerticalPadding: 8.0,
    taskTileHorizontalPadding: 16.0,
    cardVerticalPadding: 8.0,
    cardHorizontalPadding: 16.0,
    sectionInternalSpacing: 8.0,
  );

  @override
  AppSpacingTokens copyWith({
    double? taskTileVerticalPadding,
    double? taskTileHorizontalPadding,
    double? cardVerticalPadding,
    double? cardHorizontalPadding,
    double? sectionInternalSpacing,
  }) {
    return AppSpacingTokens(
      taskTileVerticalPadding: taskTileVerticalPadding ?? this.taskTileVerticalPadding,
      taskTileHorizontalPadding: taskTileHorizontalPadding ?? this.taskTileHorizontalPadding,
      cardVerticalPadding: cardVerticalPadding ?? this.cardVerticalPadding,
      cardHorizontalPadding: cardHorizontalPadding ?? this.cardHorizontalPadding,
      sectionInternalSpacing: sectionInternalSpacing ?? this.sectionInternalSpacing,
    );
  }

  @override
  AppSpacingTokens lerp(ThemeExtension<AppSpacingTokens>? other, double t) {
    if (other is! AppSpacingTokens) {
      return this;
    }
    return AppSpacingTokens(
      taskTileVerticalPadding: (taskTileVerticalPadding * (1 - t) + other.taskTileVerticalPadding * t),
      taskTileHorizontalPadding: (taskTileHorizontalPadding * (1 - t) + other.taskTileHorizontalPadding * t),
      cardVerticalPadding: (cardVerticalPadding * (1 - t) + other.cardVerticalPadding * t),
      cardHorizontalPadding: (cardHorizontalPadding * (1 - t) + other.cardHorizontalPadding * t),
      sectionInternalSpacing: (sectionInternalSpacing * (1 - t) + other.sectionInternalSpacing * t),
    );
  }
}

/// 便捷的扩展方法，用于从 BuildContext 获取 AppSpacingTokens
extension AppThemeSpacing on BuildContext {
  AppSpacingTokens get spacingTokens {
    final tokens = Theme.of(this).extension<AppSpacingTokens>();
    if (tokens == null) {
      throw StateError('AppSpacingTokens not found on Theme');
    }
    return tokens;
  }
}
