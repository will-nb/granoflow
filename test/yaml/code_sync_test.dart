import 'package:flutter_test/flutter_test.dart';
import 'helpers/yaml_test_utils.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// 代码同步测试
/// 
/// 测试目标：校验 YAML 与实际代码的同步
/// 
/// 检查内容：
/// - meta.file_path 指向的 Dart 文件存在
/// - Dart 文件中的类名与 meta.name 一致
/// - Dart 文件的类型与 YAML type 一致
void main() {
  // 在所有测试开始前输出警告
  setUpAll(() {
    YamlTestUtils.printTestWarning();
  });

  group('Code Sync Tests', () {
    final categories = [
      'models',
      'pages',
      'widgets',
      'providers',
      'repositories',
      'services',
    ];

    for (final category in categories) {
      group('$category code synchronization', () {
        final files = YamlTestUtils.findYamlFiles(category);

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName meta.file_path should point to existing Dart file', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');
            final filePath = meta['file_path']?.toString();

            if (filePath == null || filePath.isEmpty) {
              fail('❌ $fileName 缺少 file_path\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工确认正确的文件路径');
            }

            if (!YamlTestUtils.dartFileExists(filePath)) {
              fail('❌ $fileName 的 file_path 指向不存在的文件\n'
                  '   YAML 中的路径: $filePath\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. Dart 文件被删除或移动了\n'
                  '   2. YAML 中的路径错误\n'
                  '   3. 代码重构后 YAML 未更新\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - Dart 文件的正确位置在哪里？\n'
                  '      - 是否需要更新 YAML？\n'
                  '      - 这个 YAML 是否已过时应该删除？');
            }
          });

          test('$fileName class name should match meta.name', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');
            final className = meta['name']?.toString();
            final filePath = meta['file_path']?.toString();

            if (className == null || filePath == null) {
              // 已经在其他测试中检查过了
              return;
            }

            if (!YamlTestUtils.dartFileExists(filePath)) {
              // 已经在其他测试中检查过了
              return;
            }

            // Providers 文件的特殊处理：验证 provider 声明而不是类定义
            if (category == 'providers' && filePath.endsWith('_providers.dart')) {
              // 读取 Dart 文件内容
              final dartFile = File(path.join(YamlTestUtils.projectRoot, filePath));
              final content = dartFile.readAsStringSync();

              // 检查文件是否包含任何 Provider 声明
              final hasProviders = content.contains('Provider') || 
                                   content.contains('provider =') ||
                                   content.contains('Provider<');
              
              if (!hasProviders) {
                fail('❌ $fileName 应该包含 Provider 声明\n'
                    '   代码文件: $filePath\n'
                    '   \n'
                    '   在代码中未找到任何 Provider 声明\n'
                    '   \n'
                    '   这可能意味着:\n'
                    '   1. 这不是一个有效的 provider 文件\n'
                    '   2. 文件内容已完全改变\n'
                    '   \n'
                    '   👉 AI 不要修改！请人工判断：\n'
                    '      - 这个文件是否应该是 provider 文件？\n'
                    '      - YAML 是否需要更新或删除？');
              }
              
              // Provider 文件验证通过，跳过类名检查
              return;
            }

            // 非 Provider 文件：检查类名
            final dartFile = File(path.join(YamlTestUtils.projectRoot, filePath));
            final content = dartFile.readAsStringSync();

            // 检查类名是否存在于文件中
            final classPattern = RegExp(r'class\s+' + RegExp.escape(className) + r'\s+');
            if (!classPattern.hasMatch(content)) {
              fail('❌ $fileName 的类名与代码不一致\n'
                  '   YAML 中的类名: $className\n'
                  '   代码文件: $filePath\n'
                  '   \n'
                  '   在代码中未找到 "class $className"\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. 类被重命名了，YAML 未更新\n'
                  '   2. YAML 中的类名拼写错误\n'
                  '   3. 代码文件内容已完全改变\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 代码中的正确类名是什么？\n'
                  '      - YAML 是否需要更新？\n'
                  '      - 这个 YAML 是否应该重新生成？');
            }
          });

          test('$fileName type should match code category', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final meta = YamlTestUtils.getMap(yaml, 'meta');
            final yamlType = meta['type']?.toString()?.toLowerCase();

            // 从文件所在目录推断期望的类型
            String expectedType;
            switch (category) {
              case 'models':
                expectedType = 'model';
                break;
              case 'pages':
                expectedType = 'page';
                break;
              case 'widgets':
                expectedType = 'widget';
                break;
              case 'providers':
                expectedType = 'provider';
                break;
              case 'repositories':
                expectedType = 'repository';
                break;
              case 'services':
                expectedType = 'service';
                break;
              default:
                expectedType = category;
            }

            if (yamlType != expectedType) {
              fail('❌ $fileName 的类型与目录不匹配\n'
                  '   YAML 中的类型: $yamlType\n'
                  '   所在目录: $category (期望类型: $expectedType)\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. YAML 文件放错了目录\n'
                  '   2. meta.type 字段值错误\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 这个 YAML 应该在哪个目录？\n'
                  '      - meta.type 的正确值是什么？');
            }
          });
        }
      });
    }
  });
}

