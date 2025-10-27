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
          test('should have at least one YAML file', () {
            fail('❌ 未找到任何 $category 的 YAML 文件\n'
                '   路径: documents/architecture/$category/\n'
                '   \n'
                '   这可能意味着:\n'
                '   1. 目录不存在\n'
                '   2. 还未生成 YAML 文档\n'
                '   3. 文件被意外删除\n'
                '   \n'
                '   👉 请运行: scripts/anz yaml:create:all');
          });
        }

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName should have valid meta section', () {
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

            if (missingFields.isNotEmpty) {
              fail('❌ $fileName 缺少必填字段\n'
                  '   缺少的字段: ${missingFields.join(", ")}\n'
                  '   \n'
                  '   YAML 中的 meta: $meta\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工检查：\n'
                  '      1. YAML 是否按正确模板生成？\n'
                  '      2. 模板是否包含所有必填字段？\n'
                  '      3. 是否需要重新运行 yaml:create:all？');
            }
          });

          test('$fileName should have valid file_path', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');
            final filePath = meta['file_path']?.toString();

            if (filePath == null || filePath.isEmpty) {
              fail('❌ $fileName 的 file_path 为空\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工确认正确的文件路径');
            }

            // 检查文件路径是否有效
            if (!YamlTestUtils.dartFileExists(filePath)) {
              fail('❌ $fileName 的 file_path 指向不存在的文件\n'
                  '   YAML 中的路径: $filePath\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. 代码文件被删除或移动了\n'
                  '   2. YAML 中的路径错误\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 代码是否应该存在？位置是否正确？\n'
                  '      - YAML 是否需要更新路径？');
            }
          });

          test('$fileName should have valid schema_version', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');
            final schemaVersion = meta['schema_version'];

            if (schemaVersion == null) {
              fail('❌ $fileName 缺少 schema_version\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工确认是否需要添加 schema_version');
            }

            // schema_version 应该是数字
            if (schemaVersion is! int && schemaVersion is! String) {
              fail('❌ $fileName 的 schema_version 类型错误\n'
                  '   期望: int 或 String\n'
                  '   实际: ${schemaVersion.runtimeType}\n'
                  '   值: $schemaVersion\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工确认正确的类型');
            }
          });
        }
      });
    }
  });
}

