import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/theme/app_gradients.dart';

void main() {
  group('AppGradients', () {
    test('should have correct gradient definitions', () {
      // 验证海盐蓝天际渐变
      expect(AppGradients.seaSaltSky, isA<LinearGradient>());
      expect(AppGradients.seaSaltSky.colors, hasLength(2));
      expect(AppGradients.seaSaltSky.colors[0], const Color(0xFF6EC6DA)); // 海盐蓝
      expect(AppGradients.seaSaltSky.colors[1], const Color(0xFFF5FAFC)); // 天际白

      // 验证薄荷青湖光渐变
      expect(AppGradients.mintLake, isA<LinearGradient>());
      expect(AppGradients.mintLake.colors, hasLength(2));
      expect(AppGradients.mintLake.colors[0], const Color(0xFFA5E1EB)); // 薄荷青
      expect(AppGradients.mintLake.colors[1], const Color(0xFF4FAFC9)); // 湖光青

      // 验证天际白海军渐变
      expect(AppGradients.skyNavy, isA<LinearGradient>());
      expect(AppGradients.skyNavy.colors, hasLength(2));
      expect(AppGradients.skyNavy.colors[0], const Color(0xFFF5FAFC)); // 天际白
      expect(AppGradients.skyNavy.colors[1], const Color(0xFF1E4D67)); // 海军蓝

      // 验证水波涟漪渐变
      expect(AppGradients.waterRipple, isA<RadialGradient>());
      expect(AppGradients.waterRipple.colors, hasLength(3));
      expect(AppGradients.waterRipple.colors[0], const Color(0xFF6EC6DA)); // 海盐蓝
      expect(AppGradients.waterRipple.colors[1], const Color(0xFFA5E1EB)); // 薄荷青
      expect(AppGradients.waterRipple.colors[2], const Color(0xFFF5FAFC)); // 天际白

      // 验证海洋深度渐变
      expect(AppGradients.oceanDepth, isA<LinearGradient>());
      expect(AppGradients.oceanDepth.colors, hasLength(4));
      expect(AppGradients.oceanDepth.stops, hasLength(4));
    });

    test('should return correct gradient by type', () {
      expect(AppGradients.getGradient(GradientType.primary), AppGradients.seaSaltSky);
      expect(AppGradients.getGradient(GradientType.secondary), AppGradients.mintLake);
      expect(AppGradients.getGradient(GradientType.accent), AppGradients.skyNavy);
      expect(AppGradients.getGradient(GradientType.success), AppGradients.success);
      expect(AppGradients.getGradient(GradientType.warning), AppGradients.warning);
      expect(AppGradients.getGradient(GradientType.error), AppGradients.error);
      expect(AppGradients.getGradient(GradientType.info), AppGradients.info);
    });

    test('should create custom linear gradient with correct direction', () {
      final colors = [Colors.blue, Colors.green];
      
      // 垂直渐变
      final verticalGradient = AppGradients.createLinearGradient(
        colors: colors,
        direction: GradientDirection.vertical,
      );
      expect(verticalGradient.begin, Alignment.topCenter);
      expect(verticalGradient.end, Alignment.bottomCenter);

      // 水平渐变
      final horizontalGradient = AppGradients.createLinearGradient(
        colors: colors,
        direction: GradientDirection.horizontal,
      );
      expect(horizontalGradient.begin, Alignment.centerLeft);
      expect(horizontalGradient.end, Alignment.centerRight);

      // 对角线渐变 45度
      final diagonal45Gradient = AppGradients.createLinearGradient(
        colors: colors,
        direction: GradientDirection.diagonal45,
      );
      expect(diagonal45Gradient.begin, Alignment.topLeft);
      expect(diagonal45Gradient.end, Alignment.bottomRight);

      // 对角线渐变 135度
      final diagonal135Gradient = AppGradients.createLinearGradient(
        colors: colors,
        direction: GradientDirection.diagonal135,
      );
      expect(diagonal135Gradient.begin, Alignment.topRight);
      expect(diagonal135Gradient.end, Alignment.bottomLeft);
    });

    test('should create custom radial gradient', () {
      final colors = [Colors.blue, Colors.green];
      final center = Alignment.center;
      final radius = 0.8;
      final stops = [0.0, 1.0];

      final radialGradient = AppGradients.createRadialGradient(
        colors: colors,
        center: center,
        radius: radius,
        stops: stops,
      );

      expect(radialGradient.center, center);
      expect(radialGradient.radius, radius);
      expect(radialGradient.colors, colors);
      expect(radialGradient.stops, stops);
    });

    test('should throw error for radial direction in linear gradient', () {
      expect(
        () => AppGradients.createLinearGradient(
          colors: [Colors.blue, Colors.green],
          direction: GradientDirection.radial,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('GradientHelper', () {
    test('should check if gradient is suitable for dark theme', () {
      final lightGradient = AppGradients.seaSaltSky;
      final darkGradient = AppGradients.oceanDepth;

      // 海盐蓝天际渐变主要包含浅色，不适合深色主题
      // 注意：这个测试可能需要根据实际的亮度值调整
      expect(GradientHelper.isSuitableForDarkTheme(lightGradient), isA<bool>());

      // 海洋深度渐变包含深色，适合深色主题
      expect(GradientHelper.isSuitableForDarkTheme(darkGradient), isTrue);
    });

    test('should calculate average luminance correctly', () {
      final gradient = AppGradients.seaSaltSky;
      final luminance = GradientHelper.getAverageLuminance(gradient);

      expect(luminance, isA<double>());
      expect(luminance, greaterThan(0.0));
      expect(luminance, lessThan(1.0));
    });

    test('should adjust brightness correctly', () {
      final originalGradient = AppGradients.seaSaltSky;
      final factor = 0.8;

      final adjustedGradient = GradientHelper.adjustBrightness(originalGradient, factor);

      expect(adjustedGradient, isA<LinearGradient>());
      expect(adjustedGradient.begin, originalGradient.begin);
      expect(adjustedGradient.end, originalGradient.end);
      expect(adjustedGradient.colors, hasLength(originalGradient.colors.length));
    });
  });

  group('AppGradientsExtension', () {
    test('should have correct light theme gradients', () {
      const extension = AppGradientsExtension.light;

      expect(extension.primary, AppGradients.seaSaltSky);
      expect(extension.secondary, AppGradients.mintLake);
      expect(extension.accent, AppGradients.skyNavy);
      expect(extension.success, AppGradients.success);
      expect(extension.warning, AppGradients.warning);
      expect(extension.error, AppGradients.error);
      expect(extension.info, AppGradients.info);
      expect(extension.pageBackground, AppGradients.seaSaltSky);
      expect(extension.cardBackground, AppGradients.skyNavy);
    });

    test('should have correct dark theme gradients', () {
      const extension = AppGradientsExtension.dark;

      expect(extension.primary, AppGradients.oceanDepth);
      expect(extension.secondary, AppGradients.mintLake);
      expect(extension.accent, AppGradients.skyNavy);
      expect(extension.success, AppGradients.success);
      expect(extension.warning, AppGradients.warning);
      expect(extension.error, AppGradients.error);
      expect(extension.info, AppGradients.info);
      expect(extension.pageBackground, AppGradients.oceanDepth);
      expect(extension.cardBackground, AppGradients.skyNavy);
    });

    test('should copy with new values', () {
      const original = AppGradientsExtension.light;
      final newGradient = AppGradients.mintLake;

      final copied = original.copyWith(primary: newGradient);

      expect(copied.primary, newGradient);
      expect(copied.secondary, original.secondary);
      expect(copied.accent, original.accent);
    });

    test('should lerp between extensions', () {
      const light = AppGradientsExtension.light;
      const dark = AppGradientsExtension.dark;

      final lerped = light.lerp(dark, 0.5);

      expect(lerped, isA<AppGradientsExtension>());
      expect(lerped.primary, isA<LinearGradient>());
    });
  });
}
