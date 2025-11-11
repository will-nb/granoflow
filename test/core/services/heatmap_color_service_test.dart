import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/heatmap_color_service.dart';

void main() {
  group('HeatmapColorService', () {
    late HeatmapColorService service;

    setUpAll(() async {
      service = await HeatmapColorService.getInstance();
    });

    group('getHeatmapColor', () {
      test('应该为无数据返回浅灰色', () {
        final colorLight = service.getHeatmapColor(0, Brightness.light);
        final colorDark = service.getHeatmapColor(0, Brightness.dark);
        
        expect(colorLight, isA<Color>());
        expect(colorDark, isA<Color>());
        // 浅灰色检查
        expect(colorLight.computeLuminance(), greaterThan(0.8));
        expect(colorDark.computeLuminance(), lessThan(0.3));
      });

      test('应该为低强度返回浅绿色', () {
        final color = service.getHeatmapColor(15, Brightness.light);
        expect(color, isA<Color>());
        // 检查是否为绿色系
        expect(color.red, lessThan(color.green));
        expect(color.blue, lessThan(color.green));
      });

      test('应该为中等强度返回中绿色', () {
        final color = service.getHeatmapColor(45, Brightness.light);
        expect(color, isA<Color>());
        expect(color.red, lessThan(color.green));
      });

      test('应该为高强度返回深绿色', () {
        final color = service.getHeatmapColor(150, Brightness.light);
        expect(color, isA<Color>());
        expect(color.red, lessThan(color.green));
      });

      test('应该根据主题模式返回不同透明度', () {
        final colorLight = service.getHeatmapColor(60, Brightness.light);
        final colorDark = service.getHeatmapColor(60, Brightness.dark);
        
        expect(colorLight, isNot(equals(colorDark)));
      });
    });
  });
}
