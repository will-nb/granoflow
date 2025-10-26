import 'package:flutter/material.dart';

import 'app_color_schemes.dart';
import 'app_color_tokens.dart';
import 'app_gradients.dart';
import 'ocean_breeze_color_schemes.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    const colorScheme = AppColorSchemes.light;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: 'Inter',
      textTheme: _buildTextTheme(colorScheme, Brightness.light),

      // Modern AppBar with subtle elevation
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _buildTextTheme(colorScheme, Brightness.light).titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Modern Card design
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Modern Button designs
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Modern SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: _buildTextTheme(colorScheme, Brightness.light).bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),

      // Modern Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        // 使用主题色作为选中状态的颜色，去掉椭圆背景
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _buildTextTheme(colorScheme, Brightness.light).labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary, // 选中状态使用主题色
            );
          }
          return _buildTextTheme(colorScheme, Brightness.light).labelMedium?.copyWith(
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
      ),

      // Modern Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 4,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Modern Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 4,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      extensions: const <ThemeExtension<dynamic>>[
        AppColorTokens.light,
        AppGradientsExtension.light,
      ],
    );
  }

  static ThemeData dark() {
    const colorScheme = AppColorSchemes.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: OceanBreezeColorSchemes.darkNight,
      fontFamily: 'Inter',
      textTheme: _buildTextTheme(colorScheme, Brightness.dark),

      // Modern AppBar with subtle elevation
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 2,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _buildTextTheme(colorScheme, Brightness.dark).titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Modern Card design
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Modern Button designs
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Modern SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: _buildTextTheme(colorScheme, Brightness.dark).bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),

      // Modern Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        // 使用主题色作为选中状态的颜色，去掉椭圆背景
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _buildTextTheme(colorScheme, Brightness.dark).labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary, // 选中状态使用主题色
            );
          }
          return _buildTextTheme(colorScheme, Brightness.dark).labelMedium?.copyWith(
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
      ),

      // Modern Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 4,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Modern Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 4,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      extensions: const <ThemeExtension<dynamic>>[
        AppColorTokens.dark,
        AppGradientsExtension.dark,
      ],
    );
  }

  static TextTheme _buildTextTheme(
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
}
