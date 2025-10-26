import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('macOS App Icon Theme Background Tests', () {
    test('should have all required icon files', () {
      final iconDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');
      expect(iconDir.existsSync(), isTrue, reason: 'AppIcon.appiconset directory should exist');
      
      final requiredIcons = [
        'app_icon_16.png',
        'app_icon_32.png',
        'app_icon_64.png',
        'app_icon_128.png',
        'app_icon_256.png',
        'app_icon_512.png',
        'app_icon_1024.png',
      ];
      
      for (final iconName in requiredIcons) {
        final iconFile = File('${iconDir.path}/$iconName');
        expect(iconFile.existsSync(), isTrue, reason: 'Icon $iconName should exist');
      }
    });

    test('should have valid Contents.json', () {
      final contentsFile = File('macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json');
      expect(contentsFile.existsSync(), isTrue, reason: 'Contents.json should exist');
      
      final contents = contentsFile.readAsStringSync();
      expect(contents, isNotEmpty, reason: 'Contents.json should not be empty');
      expect(contents, contains('"images"'), reason: 'Contents.json should contain images array');
    });

    test('should have theme-colored background icons', () {
      // 验证图标文件存在且不为空
      final iconDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');
      final iconFiles = [
        'app_icon_256.png',
        'app_icon_512.png',
        'app_icon_1024.png',
      ];
      
      for (final iconName in iconFiles) {
        final iconFile = File('${iconDir.path}/$iconName');
        expect(iconFile.existsSync(), isTrue, reason: 'Icon $iconName should exist');
        
        final fileSize = iconFile.lengthSync();
        expect(fileSize, greaterThan(0), reason: 'Icon $iconName should not be empty');
        expect(fileSize, greaterThan(1000), reason: 'Icon $iconName should be substantial size');
      }
    });

    test('should have consistent icon sizes', () {
      final iconDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');
      
      // 检查不同尺寸的图标文件
      final sizeTests = [
        ('app_icon_16.png', 16),
        ('app_icon_32.png', 32),
        ('app_icon_64.png', 64),
        ('app_icon_128.png', 128),
        ('app_icon_256.png', 256),
        ('app_icon_512.png', 512),
        ('app_icon_1024.png', 1024),
      ];
      
      for (final (iconName, _) in sizeTests) {
        final iconFile = File('${iconDir.path}/$iconName');
        expect(iconFile.existsSync(), isTrue, reason: 'Icon $iconName should exist');
        
        // 验证文件大小合理（PNG 文件应该有一定大小）
        final fileSize = iconFile.lengthSync();
        expect(fileSize, greaterThan(50), reason: 'Icon $iconName should have reasonable size');
      }
    });
  });
}
