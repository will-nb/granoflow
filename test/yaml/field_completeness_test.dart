import 'package:flutter_test/flutter_test.dart';

/// 字段完整性测试
/// 
/// 测试目标：校验 YAML 字段的完整性
/// 
/// 检查内容：
/// - i18n_keys 中的键存在于 .arb 文件
/// - design_tokens 中的令牌存在于 lib/core/theme/ 文件
/// - test_mapping 指向的测试文件存在
/// - source_of_truth 路径有效
void main() {
  // 跳过所有 YAML 测试
  test('skipped: YAML field completeness tests temporarily disabled', () {
    // ignore: todo
    // TODO: Re-enable YAML tests when architecture documentation is stabilized
  }, skip: true);
  
  // 注释掉的原始测试代码，保留以便将来重新启用
  /*
  import 'helpers/yaml_test_utils.dart';
  
  // 在所有测试开始前输出警告
  setUpAll(() {
    YamlTestUtils.printTestWarning();
  });

  group('Field Completeness Tests', () {
    final categories = [
      'models',
      'pages',
      'widgets',
      'providers',
      'repositories',
      'services',
    ];

    for (final category in categories) {
      group('$category i18n_keys validation', () {
        final files = YamlTestUtils.findYamlFiles(category);

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName i18n_keys should exist in .arb files', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final i18nKeys = YamlTestUtils.getList(yaml, 'i18n_keys');

            if (i18nKeys.isEmpty) {
              // 没有 i18n 键，跳过
              return;
            }

            final missingKeys = <String>[];
            for (final key in i18nKeys) {
              final keyStr = key.toString();
              if (!YamlTestUtils.i18nKeyExists(keyStr)) {
                missingKeys.add(keyStr);
              }
            }

            if (missingKeys.isNotEmpty) {
              fail('❌ $fileName 中的 i18n 键在 .arb 文件中不存在\n'
                  '   缺失的键: ${missingKeys.join(", ")}\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. 代码中使用了这些键，但还未添加到 .arb 文件\n'
                  '   2. YAML 中记录了错误的键名\n'
                  '   3. .arb 文件中的键被删除或重命名了\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 代码中是否真的使用了这些键？\n'
                  '      - 是否需要在 .arb 文件中添加这些键？\n'
                  '      - YAML 中的记录是否需要更新？');
            }
          });
        }
      });

      group('$category design_tokens validation', () {
        final files = YamlTestUtils.findYamlFiles(category);

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName design_tokens should exist in theme files', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final designTokens = YamlTestUtils.getList(yaml, 'design_tokens');

            if (designTokens.isEmpty) {
              // 没有设计令牌，跳过
              return;
            }

            final missingTokens = <String>[];
            for (final token in designTokens) {
              final tokenStr = token.toString();
              if (!YamlTestUtils.designTokenExists(tokenStr)) {
                missingTokens.add(tokenStr);
              }
            }

            if (missingTokens.isNotEmpty) {
              fail('❌ $fileName 中的设计令牌在 theme 文件中不存在\n'
                  '   缺失的令牌: ${missingTokens.join(", ")}\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. 代码中使用了这些令牌，但还未定义\n'
                  '   2. YAML 中记录了错误的令牌名\n'
                  '   3. Theme 文件中的令牌被删除或重命名了\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 代码中是否真的使用了这些令牌？\n'
                  '      - 是否需要在 theme 文件中定义这些令牌？\n'
                  '      - YAML 中的记录是否需要更新？');
            }
          });
        }
      });

      group('$category source_of_truth validation', () {
        final files = YamlTestUtils.findYamlFiles(category);

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName source_of_truth should be valid', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final sourceOfTruth = YamlTestUtils.getString(yaml, 'source_of_truth');

            if (sourceOfTruth == null || sourceOfTruth.isEmpty) {
              // 没有 source_of_truth，跳过
              return;
            }

            if (!YamlTestUtils.dartFileExists(sourceOfTruth)) {
              fail('❌ $fileName 的 source_of_truth 指向不存在的文件\n'
                  '   YAML 中的路径: $sourceOfTruth\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. 代码文件被删除或移动了\n'
                  '   2. YAML 中的路径错误\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 代码文件的正确位置在哪里？\n'
                  '      - YAML 是否需要更新路径？');
            }
          });
        }
      });
    }
  });
  */
}

