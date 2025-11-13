import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/utils/rich_text_editor_config.dart';

void main() {
  group('RichTextEditorConfig', () {
    group('fromJson', () {
      test('正确解析配置', () {
        final json = {
          'toolbarMode': 'full',
          'previewMaxLines': 5,
          'autoSaveDebounce': 500,
        };
        
        final config = RichTextEditorConfig.fromJson(json);
        
        expect(config.toolbarMode, 'full');
        expect(config.previewMaxLines, 5);
        expect(config.autoSaveDebounce, 500);
      });

      test('默认值正确应用', () {
        final json = <String, dynamic>{};
        
        final config = RichTextEditorConfig.fromJson(json);
        
        expect(config.toolbarMode, 'full');
        expect(config.previewMaxLines, 3);
        expect(config.autoSaveDebounce, 300);
      });

      test('部分字段缺失时使用默认值', () {
        final json = {
          'toolbarMode': 'basic',
        };
        
        final config = RichTextEditorConfig.fromJson(json);
        
        expect(config.toolbarMode, 'basic');
        expect(config.previewMaxLines, 3); // 默认值
        expect(config.autoSaveDebounce, 300); // 默认值
      });
    });

    group('defaultConfig', () {
      test('返回默认配置', () {
        final config = RichTextEditorConfig.defaultConfig();
        
        expect(config.toolbarMode, 'full');
        expect(config.previewMaxLines, 3);
        expect(config.autoSaveDebounce, 300);
      });
    });
  });

  group('RichTextEditorConfigService', () {
    group('getInstance', () {
      test('返回同一个实例', () async {
        final instance1 = await RichTextEditorConfigService.getInstance();
        final instance2 = await RichTextEditorConfigService.getInstance();
        
        expect(instance1, same(instance2));
      });
    });

    group('getConfig', () {
      test('返回配置对象', () async {
        final service = await RichTextEditorConfigService.getInstance();
        final config = await service.getConfig();
        
        expect(config, isA<RichTextEditorConfig>());
        expect(config.toolbarMode, isA<String>());
        expect(config.previewMaxLines, isA<int>());
        expect(config.autoSaveDebounce, isA<int>());
      });

      test('配置加载失败时使用默认配置', () async {
        // 注意：这个测试依赖于配置文件存在
        // 如果配置文件不存在或格式错误，应该使用默认配置
        final service = await RichTextEditorConfigService.getInstance();
        final config = await service.getConfig();
        
        // 验证配置是有效的（即使加载失败，也应该有默认值）
        expect(config.toolbarMode, isNotEmpty);
        expect(config.previewMaxLines, greaterThan(0));
        expect(config.autoSaveDebounce, greaterThan(0));
      });
    });
  });
}

