import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/core/theme/app_color_schemes.dart';
import 'package:granoflow/core/theme/app_color_tokens.dart';

void main() {
  group('AppTheme', () {
    testWidgets('light theme uses correct Ocean Breeze colors', (tester) async {
      final theme = AppTheme.light();
      
      // 验证主色调 - 海盐蓝
      expect(theme.colorScheme.primary, const Color(0xFF6EC6DA)); // 海盐蓝
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF)); // 白色
      expect(theme.colorScheme.primaryContainer, const Color(0xFFA5E1EB)); // 薄荷青
      
      // 验证强调色 - 湖光青
      expect(theme.colorScheme.secondary, const Color(0xFF4FAFC9)); // 湖光青
      expect(theme.colorScheme.secondaryContainer, const Color(0xFFD9E4EA)); // 银灰
      
      // 验证第三色 - 薄荷青
      expect(theme.colorScheme.tertiary, const Color(0xFFA5E1EB)); // 薄荷青
      
      // 验证错误色 - 柔粉红
      expect(theme.colorScheme.error, const Color(0xFFF48B8B)); // 柔粉红
      
      // 验证表面色
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF)); // 白色
      expect(theme.colorScheme.onSurface, const Color(0xFF1E4D67)); // 海军蓝
      
      // 验证边框色
      expect(theme.colorScheme.outline, const Color(0xFFD9E4EA)); // 银灰
    });

    testWidgets('light theme uses correct AppColorTokens', (tester) async {
      final theme = AppTheme.light();
      final colorTokens = theme.extension<AppColorTokens>();
      
      expect(colorTokens, isNotNull);
      expect(colorTokens!.success, const Color(0xFF7ED2A8)); // 柔和薄荷绿
      expect(colorTokens.warning, const Color(0xFFFFD48A)); // 柔暖黄
      expect(colorTokens.info, const Color(0xFF81C8DD)); // 较浅蓝灰
      expect(colorTokens.highlight, const Color(0xFFF5FAFC)); // 天际白
      expect(colorTokens.disabled, const Color(0xFFA5B7C0)); // 禁用文字
    });

    testWidgets('AppColorSchemes.light has correct values', (tester) async {
      const colorScheme = AppColorSchemes.light;
      
      // 验证主色层级 - 海盐蓝
      expect(colorScheme.primary, const Color(0xFF6EC6DA)); // 海盐蓝
      expect(colorScheme.onPrimary, const Color(0xFFFFFFFF)); // 白色
      expect(colorScheme.primaryContainer, const Color(0xFFA5E1EB)); // 薄荷青
      
      // 验证强调色 - 湖光青
      expect(colorScheme.secondary, const Color(0xFF4FAFC9)); // 湖光青
      expect(colorScheme.secondaryContainer, const Color(0xFFD9E4EA)); // 银灰
      
      // 验证第三色 - 薄荷青
      expect(colorScheme.tertiary, const Color(0xFFA5E1EB)); // 薄荷青
      
      // 验证错误色 - 柔粉红
      expect(colorScheme.error, const Color(0xFFF48B8B)); // 柔粉红
      
      // 验证表面色
      expect(colorScheme.surface, const Color(0xFFFFFFFF)); // 白色
      expect(colorScheme.onSurface, const Color(0xFF1E4D67)); // 海军蓝
      
      // 验证边框色
      expect(colorScheme.outline, const Color(0xFFD9E4EA)); // 银灰
    });

    testWidgets('AppColorTokens.light has correct values', (tester) async {
      const colorTokens = AppColorTokens.light;
      
      // 验证语义颜色 - Ocean Breeze 配色
      expect(colorTokens.success, const Color(0xFF7ED2A8)); // 柔和薄荷绿
      expect(colorTokens.onSuccess, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorTokens.warning, const Color(0xFFFFD48A)); // 柔暖黄
      expect(colorTokens.onWarning, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorTokens.info, const Color(0xFF81C8DD)); // 较浅蓝灰
      expect(colorTokens.onInfo, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorTokens.highlight, const Color(0xFFF5FAFC)); // 天际白
      expect(colorTokens.onHighlight, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorTokens.disabled, const Color(0xFFA5B7C0)); // 禁用文字
      expect(colorTokens.onDisabled, const Color(0xFF4C6F80)); // 次文字
    });

    testWidgets('theme text colors follow Ocean Breeze palette', (tester) async {
      final theme = AppTheme.light();
      final textTheme = theme.textTheme;
      
      // 验证标题颜色 - 海军蓝
      expect(textTheme.headlineLarge?.color, const Color(0xFF1E4D67)); // 海军蓝
      expect(textTheme.titleLarge?.color, const Color(0xFF1E4D67)); // 海军蓝
      
      // 验证正文字体颜色 - 海军蓝
      expect(textTheme.bodyLarge?.color, const Color(0xFF1E4D67)); // 海军蓝
      expect(textTheme.bodyMedium?.color, const Color(0xFF1E4D67)); // 海军蓝
    });

    testWidgets('dark theme uses correct Ocean Breeze colors', (tester) async {
      final theme = AppTheme.dark();
      
      // 验证主色调 - 湖光青
      expect(theme.colorScheme.primary, const Color(0xFF4FAFC9)); // 湖光青
      expect(theme.colorScheme.onPrimary, const Color(0xFF1E4D67)); // 海军蓝
      expect(theme.colorScheme.primaryContainer, const Color(0xFF6EC6DA)); // 海盐蓝
      
      // 验证强调色 - 薄荷青
      expect(theme.colorScheme.secondary, const Color(0xFFA5E1EB)); // 薄荷青
      expect(theme.colorScheme.secondaryContainer, const Color(0xFF4C6F80)); // 次文字
      
      // 验证第三色 - 天际白
      expect(theme.colorScheme.tertiary, const Color(0xFFF5FAFC)); // 天际白
      
      // 验证错误色 - 柔粉红
      expect(theme.colorScheme.error, const Color(0xFFF48B8B)); // 柔粉红
      
      // 验证表面色
      expect(theme.colorScheme.surface, const Color(0xFF1E4D67)); // 海军蓝
      expect(theme.colorScheme.onSurface, const Color(0xFFF5FAFC)); // 天际白
      
      // 验证边框色
      expect(theme.colorScheme.outline, const Color(0xFF4C6F80)); // 次文字
    });

    testWidgets('dark theme uses correct AppColorTokens', (tester) async {
      final theme = AppTheme.dark();
      final colorTokens = theme.extension<AppColorTokens>();
      
      expect(colorTokens, isNotNull);
      expect(colorTokens!.success, const Color(0xFF7ED2A8)); // 柔和薄荷绿
      expect(colorTokens.warning, const Color(0xFFFFD48A)); // 柔暖黄
      expect(colorTokens.info, const Color(0xFF81C8DD)); // 较浅蓝灰
      expect(colorTokens.highlight, const Color(0xFF4C6F80)); // 次文字色
      expect(colorTokens.disabled, const Color(0xFFA5B7C0)); // 禁用文字
    });

    testWidgets('AppColorSchemes.dark has correct values', (tester) async {
      const colorScheme = AppColorSchemes.dark;
      
      // 验证主色层级 - 湖光青
      expect(colorScheme.primary, const Color(0xFF4FAFC9)); // 湖光青
      expect(colorScheme.onPrimary, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorScheme.primaryContainer, const Color(0xFF6EC6DA)); // 海盐蓝
      
      // 验证强调色 - 薄荷青
      expect(colorScheme.secondary, const Color(0xFFA5E1EB)); // 薄荷青
      expect(colorScheme.secondaryContainer, const Color(0xFF4C6F80)); // 次文字
      
      // 验证第三色 - 天际白
      expect(colorScheme.tertiary, const Color(0xFFF5FAFC)); // 天际白
      
      // 验证错误色 - 柔粉红
      expect(colorScheme.error, const Color(0xFFF48B8B)); // 柔粉红
      
      // 验证表面色
      expect(colorScheme.surface, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorScheme.onSurface, const Color(0xFFF5FAFC)); // 天际白
      
      // 验证边框色
      expect(colorScheme.outline, const Color(0xFF4C6F80)); // 次文字
    });

    testWidgets('AppColorTokens.dark has correct values', (tester) async {
      const colorTokens = AppColorTokens.dark;
      
      // 验证语义颜色 - Ocean Breeze 深色主题
      expect(colorTokens.success, const Color(0xFF7ED2A8)); // 柔和薄荷绿
      expect(colorTokens.onSuccess, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorTokens.warning, const Color(0xFFFFD48A)); // 柔暖黄
      expect(colorTokens.onWarning, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorTokens.info, const Color(0xFF81C8DD)); // 较浅蓝灰
      expect(colorTokens.onInfo, const Color(0xFF1E4D67)); // 海军蓝
      expect(colorTokens.highlight, const Color(0xFF4C6F80)); // 次文字色
      expect(colorTokens.onHighlight, const Color(0xFFF5FAFC)); // 天际白
      expect(colorTokens.disabled, const Color(0xFFA5B7C0)); // 禁用文字
      expect(colorTokens.onDisabled, const Color(0xFF4C6F80)); // 次文字
    });

    testWidgets('dark theme text colors follow Ocean Breeze palette', (tester) async {
      final theme = AppTheme.dark();
      final textTheme = theme.textTheme;
      
      // 验证标题颜色 - 天际白
      expect(textTheme.headlineLarge?.color, const Color(0xFFF5FAFC)); // 天际白
      expect(textTheme.titleLarge?.color, const Color(0xFFF5FAFC)); // 天际白
      
      // 验证正文字体颜色 - 天际白
      expect(textTheme.bodyLarge?.color, const Color(0xFFF5FAFC)); // 天际白
      expect(textTheme.bodyMedium?.color, const Color(0xFFF5FAFC)); // 天际白
    });
  });
}