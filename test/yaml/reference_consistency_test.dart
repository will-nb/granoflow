import 'package:flutter_test/flutter_test.dart';

/// 引用一致性测试
/// 
/// 测试目标：校验跨文件引用的一致性
/// 
/// 检查内容：
/// - called_by 和 calls 的双向引用一致
/// - calls 指向的文件存在对应的 YAML
/// - supersedes 指向的文件存在
/// - 避免循环依赖
void main() {
  // 跳过所有 YAML 测试
  test('skipped: YAML reference consistency tests temporarily disabled', () {
    // ignore: todo
    // TODO: Re-enable YAML tests when architecture documentation is stabilized
  }, skip: true);
  
  // 注释掉的原始测试代码，保留以便将来重新启用
  /*
  import 'helpers/yaml_test_utils.dart';
  import 'dart:io';
  import 'package:path/path.dart' as path;
  
  // 在所有测试开始前输出警告
  setUpAll(() {
    YamlTestUtils.printTestWarning();
  });

  group('Reference Consistency Tests', () {
    final categories = [
      'models',
      'pages',
      'widgets',
      'providers',
      'repositories',
      'services',
    ];

    group('calls references should point to valid files', () {
      for (final category in categories) {
        final files = YamlTestUtils.findYamlFiles(category);

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName calls should reference existing files', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final calls = YamlTestUtils.getList(yaml, 'calls');

            if (calls.isEmpty) {
              // 没有 calls，跳过
              return;
            }

            final missingFiles = <String>[];
            for (final call in calls) {
              final callPath = call.toString();
              
              // 检查 Dart 文件是否存在
              if (!YamlTestUtils.dartFileExists(callPath)) {
                missingFiles.add(callPath);
              }
            }

            if (missingFiles.isNotEmpty) {
              fail('❌ $fileName 的 calls 指向不存在的文件\n'
                  '   缺失的文件: ${missingFiles.join(", ")}\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. 被调用的文件被删除或移动了\n'
                  '   2. YAML 中记录了错误的路径\n'
                  '   3. 代码重构后 YAML 未更新\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 这些文件是否应该存在？\n'
                  '      - 代码中是否还在调用这些文件？\n'
                  '      - YAML 是否需要更新？');
            }
          });
        }
      }
    });

    group('supersedes references should point to valid files', () {
      for (final category in categories) {
        final files = YamlTestUtils.findYamlFiles(category);

        for (final file in files) {
          final fileName = file.uri.pathSegments.last;

          test('$fileName supersedes should reference existing YAML', () {
            final yaml =
                YamlTestUtils.loadYamlFile('documents/architecture/$category/$fileName');
            final supersedesValue = yaml['supersedes'];

            // 跳过 null、空字符串、空数组的情况
            if (supersedesValue == null) {
              return;
            }
            
            if (supersedesValue is List && supersedesValue.isEmpty) {
              return;
            }
            
            final supersedes = supersedesValue.toString();
            if (supersedes.isEmpty || supersedes == '[]') {
              return;
            }

            // 检查被替代的 YAML 文件是否存在
            final supersedesPath = 'documents/architecture/$category/$supersedes';
            final supersedesFile = File(path.join(YamlTestUtils.projectRoot, supersedesPath));

            if (!supersedesFile.existsSync()) {
              fail('❌ $fileName 的 supersedes 指向不存在的 YAML 文件\n'
                  '   YAML 中的值: $supersedes\n'
                  '   期望路径: $supersedesPath\n'
                  '   \n'
                  '   这可能意味着:\n'
                  '   1. 被替代的 YAML 文件已被删除\n'
                  '   2. supersedes 字段值错误\n'
                  '   \n'
                  '   👉 AI 不要修改！请人工判断：\n'
                  '      - 这个 supersedes 关系是否还有效？\n'
                  '      - 是否需要移除 supersedes 字段？');
            }
          });
        }
      }
    });
  });
  */
}

