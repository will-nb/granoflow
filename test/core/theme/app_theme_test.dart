import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/core/theme/app_color_schemes.dart';
import 'package:granoflow/core/theme/app_color_tokens.dart';

void main() {
  group('AppTheme', () {
    testWidgets('light theme uses correct original colors', (tester) async {
      final theme = AppTheme.light();
      
      // 验证主色调
      expect(theme.colorScheme.primary, const Color(0xFF2B5797)); // 深蓝色
      expect(theme.colorScheme.onPrimary, const Color(0xFFFFFFFF)); // 白色
      expect(theme.colorScheme.primaryContainer, const Color(0xFFD0E3FF)); // 浅蓝色
      
      // 验证强调色
      expect(theme.colorScheme.secondary, const Color(0xFF4A4A4A)); // 深灰色
      expect(theme.colorScheme.secondaryContainer, const Color(0xFFDFE1E8)); // 浅灰色
      
      // 验证第三色
      expect(theme.colorScheme.tertiary, const Color(0xFF9C27B0)); // 紫色
      
      // 验证错误色
      expect(theme.colorScheme.error, const Color(0xFFB71C1C)); // 深红色
      
      // 验证表面色
      expect(theme.colorScheme.surface, const Color(0xFFFFFFFF)); // 白色
      expect(theme.colorScheme.onSurface, const Color(0xFF1A1C1E)); // 深色文字
      
      // 验证边框色
      expect(theme.colorScheme.outline, const Color(0xFF72777F)); // 灰色边框
    });

    testWidgets('light theme uses correct AppColorTokens', (tester) async {
      final theme = AppTheme.light();
      final colorTokens = theme.extension<AppColorTokens>();
      
      expect(colorTokens, isNotNull);
      expect(colorTokens!.success, const Color(0xFF2E7D32)); // 深绿色
      expect(colorTokens.warning, const Color(0xFFF57F17)); // 深橙色
      expect(colorTokens.info, const Color(0xFF1565C0)); // 信息蓝色
      expect(colorTokens.highlight, const Color(0xFFF5F5F5)); // 浅灰色
      expect(colorTokens.disabled, const Color(0xFF757575)); // 禁用色
    });

    testWidgets('AppColorSchemes.light has correct values', (tester) async {
      const colorScheme = AppColorSchemes.light;
      
      // 验证主色层级
      expect(colorScheme.primary, const Color(0xFF2B5797)); // 深蓝色
      expect(colorScheme.onPrimary, const Color(0xFFFFFFFF)); // 白色
      expect(colorScheme.primaryContainer, const Color(0xFFD0E3FF)); // 浅蓝色
      
      // 验证强调色
      expect(colorScheme.secondary, const Color(0xFF4A4A4A)); // 深灰色
      expect(colorScheme.secondaryContainer, const Color(0xFFDFE1E8)); // 浅灰色
      
      // 验证第三色
      expect(colorScheme.tertiary, const Color(0xFF9C27B0)); // 紫色
      
      // 验证错误色
      expect(colorScheme.error, const Color(0xFFB71C1C)); // 深红色
      
      // 验证表面色
      expect(colorScheme.surface, const Color(0xFFFFFFFF)); // 白色
      expect(colorScheme.onSurface, const Color(0xFF1A1C1E)); // 深色文字
      
      // 验证边框色
      expect(colorScheme.outline, const Color(0xFF72777F)); // 灰色边框
    });

    testWidgets('AppColorTokens.light has correct values', (tester) async {
      const colorTokens = AppColorTokens.light;
      
      // 验证语义颜色
      expect(colorTokens.success, const Color(0xFF2E7D32)); // 深绿色
      expect(colorTokens.onSuccess, const Color(0xFFFFFFFF)); // 白色
      expect(colorTokens.warning, const Color(0xFFF57F17)); // 深橙色
      expect(colorTokens.onWarning, const Color(0xFF000000)); // 黑色
      expect(colorTokens.info, const Color(0xFF1565C0)); // 信息蓝色
      expect(colorTokens.onInfo, const Color(0xFFFFFFFF)); // 白色
      expect(colorTokens.highlight, const Color(0xFFF5F5F5)); // 浅灰色
      expect(colorTokens.onHighlight, const Color(0xFF000000)); // 黑色
      expect(colorTokens.disabled, const Color(0xFF757575)); // 禁用色
      expect(colorTokens.onDisabled, const Color(0xFFFFFFFF)); // 白色
    });

    testWidgets('theme text colors follow original palette', (tester) async {
      final theme = AppTheme.light();
      final textTheme = theme.textTheme;
      
      // 验证标题颜色
      expect(textTheme.headlineLarge?.color, const Color(0xFF1A1C1E)); // 深色文字
      expect(textTheme.titleLarge?.color, const Color(0xFF1A1C1E)); // 深色文字
      
      // 验证正文字体颜色
      expect(textTheme.bodyLarge?.color, const Color(0xFF1A1C1E)); // 深色文字
      expect(textTheme.bodyMedium?.color, const Color(0xFF1A1C1E)); // 深色文字
    });

    testWidgets('dark theme uses correct original colors', (tester) async {
      final theme = AppTheme.dark();
      
      // 验证主色调
      expect(theme.colorScheme.primary, const Color(0xFFA4C8FF)); // 浅蓝色
      expect(theme.colorScheme.onPrimary, const Color(0xFF002F63)); // 深蓝色
      expect(theme.colorScheme.primaryContainer, const Color(0xFF053970)); // 深蓝色容器
      
      // 验证强调色
      expect(theme.colorScheme.secondary, const Color(0xFFC2C5CD)); // 浅灰色
      expect(theme.colorScheme.secondaryContainer, const Color(0xFF3C3F46)); // 深灰色容器
      
      // 验证第三色
      expect(theme.colorScheme.tertiary, const Color(0xFFE6B8FF)); // 浅紫色
      
      // 验证错误色
      expect(theme.colorScheme.error, const Color(0xFFFFB4AB)); // 浅红色
      
      // 验证表面色
      expect(theme.colorScheme.surface, const Color(0xFF111315)); // 深色表面
      expect(theme.colorScheme.onSurface, const Color(0xFFE2E2E6)); // 浅色文字
      
      // 验证边框色
      expect(theme.colorScheme.outline, const Color(0xFF8D9199)); // 灰色边框
    });

    testWidgets('dark theme uses correct AppColorTokens', (tester) async {
      final theme = AppTheme.dark();
      final colorTokens = theme.extension<AppColorTokens>();
      
      expect(colorTokens, isNotNull);
      expect(colorTokens!.success, const Color(0xFF81C784)); // 浅绿色
      expect(colorTokens.warning, const Color(0xFFFFB74D)); // 浅橙色
      expect(colorTokens.info, const Color(0xFF90A4AE)); // 浅蓝灰色
      expect(colorTokens.highlight, const Color(0xFF3C3830)); // 深色高亮
      expect(colorTokens.disabled, const Color(0xFF6B6B6B)); // 禁用色
    });

    testWidgets('AppColorSchemes.dark has correct values', (tester) async {
      const colorScheme = AppColorSchemes.dark;
      
      // 验证主色层级
      expect(colorScheme.primary, const Color(0xFFA4C8FF)); // 浅蓝色
      expect(colorScheme.onPrimary, const Color(0xFF002F63)); // 深蓝色
      expect(colorScheme.primaryContainer, const Color(0xFF053970)); // 深蓝色容器
      
      // 验证强调色
      expect(colorScheme.secondary, const Color(0xFFC2C5CD)); // 浅灰色
      expect(colorScheme.secondaryContainer, const Color(0xFF3C3F46)); // 深灰色容器
      
      // 验证第三色
      expect(colorScheme.tertiary, const Color(0xFFE6B8FF)); // 浅紫色
      
      // 验证错误色
      expect(colorScheme.error, const Color(0xFFFFB4AB)); // 浅红色
      
      // 验证表面色
      expect(colorScheme.surface, const Color(0xFF111315)); // 深色表面
      expect(colorScheme.onSurface, const Color(0xFFE2E2E6)); // 浅色文字
      
      // 验证边框色
      expect(colorScheme.outline, const Color(0xFF8D9199)); // 灰色边框
    });

    testWidgets('AppColorTokens.dark has correct values', (tester) async {
      const colorTokens = AppColorTokens.dark;
      
      // 验证语义颜色
      expect(colorTokens.success, const Color(0xFF81C784)); // 浅绿色
      expect(colorTokens.onSuccess, const Color(0xFF00310A)); // 深绿色
      expect(colorTokens.warning, const Color(0xFFFFB74D)); // 浅橙色
      expect(colorTokens.onWarning, const Color(0xFF1F1400)); // 深橙色
      expect(colorTokens.info, const Color(0xFF90A4AE)); // 浅蓝灰色
      expect(colorTokens.onInfo, const Color(0xFFE2E2E6)); // 浅色文字
      expect(colorTokens.highlight, const Color(0xFF3C3830)); // 深色高亮
      expect(colorTokens.onHighlight, const Color(0xFFE2E2E6)); // 浅色文字
      expect(colorTokens.disabled, const Color(0xFF6B6B6B)); // 禁用色
      expect(colorTokens.onDisabled, const Color(0xFFE2E2E6)); // 浅色文字
    });

    testWidgets('dark theme text colors follow original palette', (tester) async {
      final theme = AppTheme.dark();
      final textTheme = theme.textTheme;
      
      // 验证标题颜色
      expect(textTheme.headlineLarge?.color, const Color(0xFFE2E2E6)); // 浅色文字
      expect(textTheme.titleLarge?.color, const Color(0xFFE2E2E6)); // 浅色文字
      
      // 验证正文字体颜色
      expect(textTheme.bodyLarge?.color, const Color(0xFFE2E2E6)); // 浅色文字
      expect(textTheme.bodyMedium?.color, const Color(0xFFE2E2E6)); // 浅色文字
    });
  });
}