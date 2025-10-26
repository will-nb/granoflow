import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// TaskId生成功能一致性测试
/// 
/// 这个测试文件专门验证taskId生成功能与YAML文档的一致性，
/// 确保新的YYYYMMDD-XXXX格式被正确记录和实现。
void main() {
  group('TaskId Generation Consistency Tests', () {
    late Map yamlDoc;
    late String yamlFilePath;

    setUpAll(() async {
      // 加载YAML文档
      yamlFilePath = path.join(
        Directory.current.path,
        'documents',
        'architecture',
        'repositories',
        'task_repository.yaml',
      );
      final yamlFile = File(yamlFilePath);
      final yamlContent = await yamlFile.readAsString();
      yamlDoc = loadYaml(yamlContent);
    });

    group('TaskId Generation Format', () {
      test('YAML应该记录YYYYMMDD-XXXX格式', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        
        expect(taskIdGenerationRule['implementation'], contains('YYYYMMDD-XXXX格式'));
      });

      test('YAML应该记录基于日期的自增ID生成', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        
        expect(taskIdGenerationRule['implementation'], contains('基于日期的自增ID生成'));
      });

      test('YAML应该记录每日从0001开始', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        
        expect(taskIdGenerationRule['implementation'], contains('每日从0001开始'));
      });

      test('YAML应该记录跨天重置', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        
        expect(taskIdGenerationRule['implementation'], contains('跨天重置'));
      });
    });

    group('TaskId Parsing Format', () {
      test('YAML应该记录taskId解析规则', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdParsingRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_parsing');
        
        expect(taskIdParsingRule['description'], contains('任务 ID 解析规则'));
        expect(taskIdParsingRule['implementation'], contains('解析YYYYMMDD-XXXX格式'));
        expect(taskIdParsingRule['implementation'], contains('提取日期和后缀'));
        expect(taskIdParsingRule['implementation'], contains('支持错误处理'));
      });
    });

    group('Private Methods for TaskId', () {
      test('_generateTaskId方法应该正确描述', () {
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        final generateTaskIdMethod = privateMethods.firstWhere((method) => method['name'] == '_generateTaskId');
        
        expect(generateTaskIdMethod['return_type'], equals('Future<String>'));
        expect(generateTaskIdMethod['description'], contains('生成任务 ID (YYYYMMDD-XXXX格式)'));
        expect(generateTaskIdMethod['visibility'], equals('private'));
        
        final parameters = generateTaskIdMethod['parameters'] as List;
        expect(parameters.length, equals(1));
        expect(parameters[0]['name'], equals('now'));
        expect(parameters[0]['type'], equals('DateTime'));
        expect(parameters[0]['required'], equals(true));
      });

      test('_getLatestTask方法应该正确描述', () {
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        final getLatestTaskMethod = privateMethods.firstWhere((method) => method['name'] == '_getLatestTask');
        
        expect(getLatestTaskMethod['return_type'], equals('Future<Task?>'));
        expect(getLatestTaskMethod['description'], contains('查询最新创建的任务'));
        expect(getLatestTaskMethod['visibility'], equals('private'));
      });

      test('_parseTaskId方法应该正确描述', () {
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        final parseTaskIdMethod = privateMethods.firstWhere((method) => method['name'] == '_parseTaskId');
        
        expect(parseTaskIdMethod['return_type'], equals('Map<String, dynamic>?'));
        expect(parseTaskIdMethod['description'], contains('解析taskId格式，提取日期和后缀'));
        expect(parseTaskIdMethod['visibility'], equals('private'));
        
        final parameters = parseTaskIdMethod['parameters'] as List;
        expect(parameters.length, equals(1));
        expect(parameters[0]['name'], equals('taskId'));
        expect(parameters[0]['type'], equals('String'));
        expect(parameters[0]['required'], equals(true));
      });
    });

    group('Error Handling for TaskId', () {
      test('TaskIdGenerationException应该正确描述', () {
        final errorHandling = yamlDoc['error_handling'] as List;
        final taskIdGenerationException = errorHandling.firstWhere((error) => error['exception'] == 'TaskIdGenerationException');
        
        expect(taskIdGenerationException['description'], contains('任务ID生成异常'));
        expect(taskIdGenerationException['handling'], contains('处理任务ID生成错误并fallback到默认格式'));
      });

      test('TaskIdParseException应该正确描述', () {
        final errorHandling = yamlDoc['error_handling'] as List;
        final taskIdParseException = errorHandling.firstWhere((error) => error['exception'] == 'TaskIdParseException');
        
        expect(taskIdParseException['description'], contains('任务ID解析异常'));
        expect(taskIdParseException['handling'], contains('处理任务ID解析错误并返回null'));
      });
    });

    group('Testing Strategy for TaskId', () {
      test('应该包含taskId生成相关的单元测试', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final testNames = unitTests.map((test) => test['name']).toList();
        
        expect(testNames, contains('test_generate_task_id'));
        expect(testNames, contains('test_generate_task_id_format'));
        expect(testNames, contains('test_generate_task_id_increment'));
        expect(testNames, contains('test_generate_task_id_cross_day'));
        expect(testNames, contains('test_parse_task_id'));
        expect(testNames, contains('test_get_latest_task'));
      });

      test('应该包含taskId生成相关的集成测试', () {
        final integrationTests = yamlDoc['testing_strategy']['integration_tests'] as List;
        final testNames = integrationTests.map((test) => test['name']).toList();
        
        expect(testNames, contains('test_task_id_generation_integration'));
        expect(testNames, contains('test_task_id_uniqueness'));
      });

      test('test_generate_task_id测试描述应该正确', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id');
        
        expect(generateTaskIdTest['description'], contains('测试任务ID生成功能'));
      });

      test('test_generate_task_id_format测试描述应该正确', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdFormatTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id_format');
        
        expect(generateTaskIdFormatTest['description'], contains('测试任务ID格式验证'));
      });

      test('test_generate_task_id_increment测试描述应该正确', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdIncrementTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id_increment');
        
        expect(generateTaskIdIncrementTest['description'], contains('测试任务ID自增功能'));
      });

      test('test_generate_task_id_cross_day测试描述应该正确', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdCrossDayTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id_cross_day');
        
        expect(generateTaskIdCrossDayTest['description'], contains('测试任务ID跨天重置功能'));
      });

      test('test_parse_task_id测试描述应该正确', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final parseTaskIdTest = unitTests.firstWhere((test) => test['name'] == 'test_parse_task_id');
        
        expect(parseTaskIdTest['description'], contains('测试任务ID解析功能'));
      });

      test('test_get_latest_task测试描述应该正确', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final getLatestTaskTest = unitTests.firstWhere((test) => test['name'] == 'test_get_latest_task');
        
        expect(getLatestTaskTest['description'], contains('测试获取最新任务功能'));
      });

      test('test_task_id_generation_integration测试描述应该正确', () {
        final integrationTests = yamlDoc['testing_strategy']['integration_tests'] as List;
        final taskIdGenerationIntegrationTest = integrationTests.firstWhere((test) => test['name'] == 'test_task_id_generation_integration');
        
        expect(taskIdGenerationIntegrationTest['description'], contains('测试任务ID生成集成'));
      });

      test('test_task_id_uniqueness测试描述应该正确', () {
        final integrationTests = yamlDoc['testing_strategy']['integration_tests'] as List;
        final taskIdUniquenessTest = integrationTests.firstWhere((test) => test['name'] == 'test_task_id_uniqueness');
        
        expect(taskIdUniquenessTest['description'], contains('测试任务ID唯一性'));
      });
    });

    group('Dependencies for TaskId', () {
      test('应该包含flutter/foundation.dart导入', () {
        final imports = yamlDoc['imports'] as List;
        
        expect(imports, contains('package:flutter/foundation.dart'));
      });

      test('不应该包含dart:math导入', () {
        final imports = yamlDoc['imports'] as List;
        
        expect(imports, isNot(contains('dart:math')));
      });
    });

    group('Private Fields for TaskId', () {
      test('应该不包含_random字段', () {
        final privateFields = yamlDoc['implementation_details']['private_fields'] as List;
        final fieldNames = privateFields.map((field) => field['name']).toList();
        
        expect(fieldNames, isNot(contains('_random')));
      });

      test('应该包含_isar和_clock字段', () {
        final privateFields = yamlDoc['implementation_details']['private_fields'] as List;
        final fieldNames = privateFields.map((field) => field['name']).toList();
        
        expect(fieldNames, contains('_isar'));
        expect(fieldNames, contains('_clock'));
      });
    });

    group('Document Lock for TaskId', () {
      test('YAML文件应该被锁定防止意外修改', () {
        // 验证文件存在且可读
        expect(File(yamlFilePath).existsSync(), isTrue);
        
        // 验证taskId相关功能在多个部分都有描述
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        expect(taskIdGenerationRule, isNotNull);
        
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        final generateTaskIdMethod = privateMethods.firstWhere((method) => method['name'] == '_generateTaskId');
        expect(generateTaskIdMethod, isNotNull);
        
        final errorHandling = yamlDoc['error_handling'] as List;
        final taskIdGenerationException = errorHandling.firstWhere((error) => error['exception'] == 'TaskIdGenerationException');
        expect(taskIdGenerationException, isNotNull);
        
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id');
        expect(generateTaskIdTest, isNotNull);
      });

      test('文档应该包含完整的taskId功能描述', () {
        // 验证taskId相关功能在多个部分都有描述
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        expect(taskIdGenerationRule['implementation'], contains('YYYYMMDD-XXXX格式'));
        
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        final generateTaskIdMethod = privateMethods.firstWhere((method) => method['name'] == '_generateTaskId');
        expect(generateTaskIdMethod['description'], contains('生成任务 ID (YYYYMMDD-XXXX格式)'));
        
        final errorHandling = yamlDoc['error_handling'] as List;
        final taskIdGenerationException = errorHandling.firstWhere((error) => error['exception'] == 'TaskIdGenerationException');
        expect(taskIdGenerationException['description'], contains('任务ID生成异常'));
        
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id');
        expect(generateTaskIdTest['description'], contains('测试任务ID生成功能'));
      });
    });
  });
}
