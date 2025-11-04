import 'package:flutter/material.dart';

/// AppTheme 构建器方法
/// 
/// 包含构建主题数据的辅助方法
class AppThemeBuilders {
  /// 构建文本主题
  static TextTheme buildTextTheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) {
    // Use modern typography system instead of material2021
    final base = brightness == Brightness.dark
        ? Typography.material2021(platform: TargetPlatform.android).white
        : Typography.material2021(platform: TargetPlatform.android).black;

    // Modern adjustments for better readability and contemporary feel
    const displayAdjust = 2.0; // Slightly larger for impact
    const headlineAdjust = 1.0; // Balanced headlines
    const titleAdjust = -1.0; // More refined titles
    const bodyAdjust = -0.5; // Improved body text readability

    return base.copyWith(
      // Display styles - more prominent and modern
      displayLarge: base.displayLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: base.displayLarge?.fontSize != null
            ? base.displayLarge!.fontSize! + displayAdjust
            : null,
        fontWeight: FontWeight.w300, // Lighter weight for modern look
        letterSpacing: -1.5,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
      ),

      // Headline styles - balanced and contemporary
      headlineLarge: base.headlineLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: base.headlineLarge?.fontSize != null
            ? base.headlineLarge!.fontSize! + headlineAdjust
            : null,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
      ),

      // Title styles - refined and modern
      titleLarge: base.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: base.titleLarge?.fontSize != null
            ? base.titleLarge!.fontSize! + titleAdjust
            : null,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),

      // Body styles - improved readability
      bodyLarge: base.bodyLarge?.copyWith(
        color: colorScheme.onSurface,
        fontSize: base.bodyLarge?.fontSize != null
            ? base.bodyLarge!.fontSize! + bodyAdjust
            : null,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5, // Better line height for readability
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.5,
      ),

      // Label styles - clear and actionable
      labelLarge: base.labelLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// 构建浅色主题的导航栏主题
  static NavigationBarThemeData buildLightNavigationBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      // 使用主题色作为选中状态的颜色，去掉椭圆背景
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary, // 选中状态使用主题色
          );
        }
        return textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant, // 未选中状态使用次要文本色
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: colorScheme.primary, // 选中状态使用主题色
            size: 24,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant, // 未选中状态使用次要文本色
          size: 24,
        );
      }),
    );
  }

  /// 构建深色主题的导航栏主题
  static NavigationBarThemeData buildDarkNavigationBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      elevation: 1,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
      // 使用主题色作为选中状态的颜色，去掉椭圆背景
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary, // 选中状态使用主题色
          );
        }
        return textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant, // 未选中状态使用次要文本色
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: colorScheme.primary, // 选中状态使用主题色
            size: 24,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant, // 未选中状态使用次要文本色
          size: 24,
        );
      }),
    );
  }
}

