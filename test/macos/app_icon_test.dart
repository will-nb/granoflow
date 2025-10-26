import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('macOS App Icon Tests', () {
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
        'Contents.json',
      ];
      
      for (final icon in requiredIcons) {
        final iconFile = File('${iconDir.path}/$icon');
        expect(iconFile.existsSync(), isTrue, reason: '$icon should exist');
      }
    });
    
    test('should have valid icon file sizes', () {
      final iconDir = Directory('macos/Runner/Assets.xcassets/AppIcon.appiconset');
      
      // 检查图标文件大小是否合理（不是默认的 Flutter 图标）
      final iconFiles = {
        'app_icon_16.png': 50,     // 16px 小图标体积较小
        'app_icon_32.png': 200,    
        'app_icon_64.png': 800,    
        'app_icon_128.png': 3000,  
        'app_icon_256.png': 12000, 
        'app_icon_512.png': 28000, 
        'app_icon_1024.png': 48000,
      };
      
      for (final entry in iconFiles.entries) {
        final iconFile = File('${iconDir.path}/${entry.key}');
        if (iconFile.existsSync()) {
          final fileSize = iconFile.lengthSync();
          expect(fileSize, greaterThan(entry.value), 
            reason: '${entry.key} should be larger than ${entry.value} bytes (actual: $fileSize)');
        }
      }
    });
    
    test('should have valid Contents.json', () {
      final contentsFile = File('macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json');
      expect(contentsFile.existsSync(), isTrue, reason: 'Contents.json should exist');
      
      final contents = contentsFile.readAsStringSync();
      expect(contents, contains('"idiom" : "mac"'), reason: 'Should contain macOS idiom');
      expect(contents, contains('"size" : "16x16"'), reason: 'Should contain 16x16 size');
      expect(contents, contains('"size" : "32x32"'), reason: 'Should contain 32x32 size');
      expect(contents, contains('"size" : "128x128"'), reason: 'Should contain 128x128 size');
      expect(contents, contains('"size" : "256x256"'), reason: 'Should contain 256x256 size');
      expect(contents, contains('"size" : "512x512"'), reason: 'Should contain 512x512 size');
    });
    
    test('should have source logo file', () {
      final sourceFile = File('assets/logo/granostack-logo-transparent.png');
      expect(sourceFile.existsSync(), isTrue, reason: 'Source logo file should exist');
      
      final fileSize = sourceFile.lengthSync();
      expect(fileSize, greaterThan(30000), reason: 'Source logo should be larger than 30KB');
    });
  });
}
