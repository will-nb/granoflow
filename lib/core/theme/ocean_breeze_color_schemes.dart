import 'package:flutter/material.dart';

/// Ocean Breeze 清爽水蓝配色方案
/// 基于 ALLIE 夏日防晒主题的完整配色系统
class OceanBreezeColorSchemes {
  const OceanBreezeColorSchemes._();

  /// Ocean Breeze 浅色主题配色方案
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    // 主色调 - 海盐蓝
    primary: Color(0xFF6EC6DA),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFA5E1EB), // 薄荷青
    onPrimaryContainer: Color(0xFF1E4D67), // 海军蓝
    
    // 辅色调 - 湖光青
    secondary: Color(0xFF4FAFC9),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD9E4EA), // 银灰
    onSecondaryContainer: Color(0xFF1E4D67),
    
    // 第三色 - 薄荷青
    tertiary: Color(0xFFA5E1EB),
    onTertiary: Color(0xFF1E4D67),
    tertiaryContainer: Color(0xFFF5FAFC), // 天际白
    onTertiaryContainer: Color(0xFF1E4D67),
    
    // 错误色 - 柔粉红
    error: Color(0xFFF48B8B),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFE5E5),
    onErrorContainer: Color(0xFF690005),
    
    // 表面色
    surface: Color(0xFFFFFFFF), // 卡片背景
    onSurface: Color(0xFF1E4D67), // 主文字
    surfaceContainerHighest: Color(0xFFD9E4EA), // 银灰
    onSurfaceVariant: Color(0xFF4C6F80), // 次文字
    outline: Color(0xFFD9E4EA), // 边框色
    shadow: Color(0xFF000000),
    
    // 反向色
    inverseSurface: Color(0xFF1E4D67),
    onInverseSurface: Color(0xFFF5FAFC),
    inversePrimary: Color(0xFF4FAFC9),
    surfaceTint: Color(0xFF6EC6DA),
  );

  /// Ocean Breeze Dark - 深海流光配色方案
  /// 保持品牌调性一致：清爽、水感、透亮
  /// 暗环境下保证高对比 + 低刺眼度
  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    
    // 主色调 - 湖光青 (与测试期望一致)
    primary: Color(0xFF4FAFC9),
    onPrimary: Color(0xFF1E4D67),
    primaryContainer: Color(0xFF6EC6DA),
    onPrimaryContainer: Color(0xFFFFFFFF),
    
    // 辅色调 - 薄荷青
    secondary: Color(0xFFA5E1EB),
    onSecondary: Color(0xFF1E4D67),
    secondaryContainer: Color(0xFF4C6F80), // 次文字色，符合测试
    onSecondaryContainer: Color(0xFFFFFFFF),
    
    // 第三色 - 极光青 (Highlight)
    tertiary: Color(0xFFF5FAFC),
    onTertiary: Color(0xFF1E4D67),
    tertiaryContainer: Color(0xFF254047),
    onTertiaryContainer: Color(0xFFE7F1F3),
    
    // 错误色 - 柔粉红
    error: Color(0xFFF48B8B),
    onError: Color(0xFF1E3C49),
    errorContainer: Color(0xFF8B0000),
    onErrorContainer: Color(0xFFE7F1F3),
    
    // 背景与表面色
    surface: Color(0xFF1E4D67),
    onSurface: Color(0xFFF5FAFC),
    surfaceContainerHighest: Color(0xFF1E3C49),
    onSurfaceVariant: Color(0xFF4C6F80),
    outline: Color(0xFF4C6F80),
    shadow: Color(0xFF000000),
    
    // 反向色
    inverseSurface: Color(0xFFF5FAFC),
    onInverseSurface: Color(0xFF1E4D67),
    inversePrimary: Color(0xFF6EC6DA),
    surfaceTint: Color(0xFF4FAFC9),
  );

  /// 功能性颜色
  static const Map<String, Color> functionalColors = {
    'success': Color(0xFF7ED2A8), // 柔和薄荷绿
    'warning': Color(0xFFFFD48A), // 柔暖黄
    'error': Color(0xFFF48B8B), // 柔粉红
    'info': Color(0xFF81C8DD), // 较浅蓝灰
  };

  /// 渐变定义
  static const Map<String, List<Color>> gradients = {
    'primary': [Color(0xFF6EC6DA), Color(0xFFA5E1EB)],
    'hover': [Color(0xFF4FAFC9), Color(0xFF6EC6DA)],
    'background': [Color(0xFFE9F9FC), Color(0xFFF5FAFC)],
  };
}
