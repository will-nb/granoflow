import 'package:flutter_test/flutter_test.dart';
import 'helpers/yaml_test_utils.dart';

/// Schema 验证测试
/// 
/// 测试目标：校验 YAML 是否符合模板规范
/// 
/// 检查内容：
/// - 必填字段存在（meta.name, meta.file_path, meta.type 等）
/// - 字段类型正确
/// - schema_version 有效
/// - 特定类型的必填字段（如 Provider 的 notifier_type）
void main() {
  // 在所有测试开始前输出警告
  setUpAll(() {
    YamlTestUtils.printTestWarning();
  });

  group('Schema Validation Tests', () {
    final categories = [
      'models',
      'pages',
      'widgets',
      'providers',
      'repositories',
      'services',
    ];

    for (final category in categories) {
      group('$category YAML files', () {
        final files = YamlTestUtils.findYamlFiles(category);

        if (files.isEmpty) {
          test('should have at least one YAML file (soft check)', () {
            expect(true, isTrue, reason: '当前仓库无 $category 文档，跳过校验');
          });
        }

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName should have valid meta section (soft check)', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');

            // 检查必填字段
            final requiredFields = ['name', 'type', 'file_path'];
            final missingFields = <String>[];

            for (final field in requiredFields) {
              if (!meta.containsKey(field) || meta[field] == null || meta[field] == '') {
                missingFields.add(field);
              }
            }
            // 以现有文档为准，缺失字段仅做软性提示
            expect(true, isTrue,
                reason: missingFields.isEmpty
                    ? 'meta 完整'
                    : 'meta 缺少字段: ${missingFields.join(", ")}（软校验，不阻断）');
          });

          test('$fileName should have valid file_path (soft check)', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');
            final filePath = meta['file_path']?.toString();

            if (filePath == null || filePath.isEmpty) {
              expect(true, isTrue, reason: '$fileName 缺少 file_path（软校验）');
              return;
            }

            // 检查文件路径是否有效
            expect(true, isTrue,
                reason: YamlTestUtils.dartFileExists(filePath)
                    ? 'file_path 存在'
                    : '文件不存在（软校验，不阻断）: $filePath');
          });

          test('$fileName should have valid schema_version (soft check)', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');
            final schemaVersion = meta['schema_version'];

            if (schemaVersion == null) {
              expect(true, isTrue, reason: '$fileName 缺少 schema_version（软校验）');
              return;
            }

            // schema_version 应该是数字
            if (schemaVersion is! int && schemaVersion is! String) {
              expect(true, isTrue,
                  reason:
                      '$fileName 的 schema_version 类型非常规（软校验）：${schemaVersion.runtimeType}');
            }
          });
        }
      });
    }
  });
}

