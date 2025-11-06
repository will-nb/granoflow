import 'package:flutter/material.dart';

/// Ocean Breeze 清爽水蓝配色方案
/// 基于 ALLIE 夏日防晒主题的完整配色系统
class OceanBreezeColorSchemes {
  const OceanBreezeColorSchemes._();

  // ============ 品牌色板（单一来源） ============
  
  // 主色调常量（Light & Dark 共用）
  static const Color seaSaltBlue = Color(0xFF6EC6DA);      // 海盐蓝
  static const Color mintCyan = Color(0xFFA5E1EB);         // 薄荷青
  static const Color lakeCyan = Color(0xFF4FAFC9);         // 湖光青
  static const Color navyBlue = Color(0xFF1E4D67);         // 海军蓝
  static const Color skyWhite = Color(0xFFF5FAFC);         // 天际白
  static const Color silverGray = Color(0xFFB0C4CE);       // 银灰（加深以提高与背景对比度）
  
  // 功能色常量
  static const Color softGreen = Color(0xFF7ED2A8);        // 柔和薄荷绿
  static const Color warmYellow = Color(0xFFFFD48A);       // 柔暖黄
  static const Color softPink = Color(0xFFF48B8B);         // 柔粉红
  static const Color lightBlueGray = Color(0xFF81C8DD);    // 较浅蓝灰
  static const Color secondaryText = Color(0xFF4C6F80);    // 次文字
  static const Color disabledGray = Color(0xFFA5B7C0);     // 禁用文字
  
  // Deep 主题专用色
  static const Color deepSeaWater = Color(0xFF1A2F36);     // 深层海水（保留用于其他渐变）
  static const Color floatingWater = Color(0xFF14262C);    // 浮层水色
  static const Color darkNight = Color(0xFF0E1B20);        // 深海夜色
  static const Color darkSurface = Color(0xFF1E3C49);      // 深色表面
  static const Color auroraBlue = Color(0xFFE7F1F3);       // 极光蓝
  static const Color darkContainer = Color(0xFF254047);    // 深色容器
  
  // Light 主题专用渐变色
  static const Color veryLightSky = Color(0xFFF0F8FA);     // 极浅天际蓝
  static const Color lightSeaSalt = Color(0xFFD4EEF4);     // 轻盈海盐蓝
  
  // 其他固定色
  static const Color pureWhite = Color(0xFFFFFFFF);        // 纯白
  static const Color pureBlack = Color(0xFF000000);        // 纯黑
  static const Color errorDark = Color(0xFF690005);        // 深色错误
  static const Color errorContainerLight = Color(0xFFFFE5E5);  // 浅色错误容器
  static const Color errorContainerDark = Color(0xFF8B0000);   // 深色错误容器

  // ============ 番茄时钟专用颜色 ============
  
  // Light 模式颜色
  static const Color pomodoroTomatoRed = Color(0xFFFF6B6B);      // 番茄红
  static const Color pomodoroVibrantOrange = Color(0xFFFFA07A);  // 活力橙
  static const Color pomodoroSuccessGreen = Color(0xFF4ECDC4);   // 成功绿
  static const Color pomodoroPausedLight = Color(0xFF9E9E9E);    // 暂停灰色
  static const Color pomodoroPausedMedium = Color(0xFFBDBDBD);   // 暂停中灰
  static const Color pomodoroPausedLight2 = Color(0xFFE0E0E0);   // 暂停浅灰
  
  // Dark 模式颜色
  static const Color pomodoroDeepTomatoRed = Color(0xFFD32F2F);  // 深番茄红
  static const Color pomodoroDeepOrange = Color(0xFFFF7043);     // 深橙
  static const Color pomodoroDeepGreen = Color(0xFF26A69A);      // 深绿
  static const Color pomodoroPausedDark = Color(0xFF424242);     // 暂停深灰
  static const Color pomodoroPausedDark2 = Color(0xFF616161);    // 暂停中灰
  static const Color pomodoroPausedDark3 = Color(0xFF757575);    // 暂停浅灰

  /// Ocean Breeze 浅色主题配色方案
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    // 主色调 - 海盐蓝
    primary: seaSaltBlue,
    onPrimary: pureWhite,
    primaryContainer: mintCyan,
    onPrimaryContainer: navyBlue,
    
    // 辅色调 - 湖光青
    secondary: lakeCyan,
    onSecondary: pureWhite,
    secondaryContainer: silverGray,
    onSecondaryContainer: navyBlue,
    
    // 第三色 - 薄荷青
    tertiary: mintCyan,
    onTertiary: navyBlue,
    tertiaryContainer: skyWhite,
    onTertiaryContainer: navyBlue,
    
    // 错误色 - 柔粉红
    error: softPink,
    onError: pureWhite,
    errorContainer: errorContainerLight,
    onErrorContainer: errorDark,
    
    // 表面色
    surface: pureWhite,
    onSurface: navyBlue,
    surfaceContainerHighest: silverGray,
    onSurfaceVariant: secondaryText,
    outline: silverGray,
    shadow: pureBlack,
    
    // 反向色
    inverseSurface: navyBlue,
    onInverseSurface: skyWhite,
    inversePrimary: lakeCyan,
    surfaceTint: seaSaltBlue,
  );

  /// Ocean Breeze Dark - 深海流光配色方案
  /// 保持品牌调性一致：清爽、水感、透亮
  /// 暗环境下保证高对比 + 低刺眼度
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    
    // 主色调 - 湖光青 (与测试期望一致)
    primary: lakeCyan,
    onPrimary: navyBlue,
    primaryContainer: seaSaltBlue,
    onPrimaryContainer: pureWhite,
    
    // 辅色调 - 薄荷青
    secondary: mintCyan,
    onSecondary: navyBlue,
    secondaryContainer: secondaryText,
    onSecondaryContainer: pureWhite,
    
    // 第三色 - 极光青 (Highlight)
    tertiary: skyWhite,
    onTertiary: navyBlue,
    tertiaryContainer: darkContainer,
    onTertiaryContainer: auroraBlue,
    
    // 错误色 - 柔粉红
    error: softPink,
    onError: darkSurface,
    errorContainer: errorContainerDark,
    onErrorContainer: auroraBlue,
    
    // 背景与表面色
    surface: navyBlue,
    onSurface: skyWhite,
    surfaceContainerHighest: darkSurface,
    onSurfaceVariant: secondaryText,
    outline: secondaryText,
    shadow: pureBlack,
    
    // 反向色
    inverseSurface: skyWhite,
    onInverseSurface: navyBlue,
    inversePrimary: seaSaltBlue,
    surfaceTint: lakeCyan,
  );

  /// 功能性颜色
  static const Map<String, Color> functionalColors = {
    'success': softGreen,
    'warning': warmYellow,
    'error': softPink,
    'info': lightBlueGray,
  };

  /// 渐变定义
  static const Map<String, List<Color>> gradients = {
    'primary': [seaSaltBlue, mintCyan],
    'hover': [lakeCyan, seaSaltBlue],
    'background': [Color(0xFFE9F9FC), skyWhite],
  };
}
