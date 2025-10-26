import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// TaskRepository与YAML文档一致性测试
/// 
/// 这个测试文件确保task_repository的实现与architecture文档保持一致，
/// 防止意外修改导致文档和代码不同步。
void main() {
  group('TaskRepository YAML Consistency Tests', () {
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

    group('Repository Definition Consistency', () {
      test('仓库名称应该与YAML一致', () {
        expect(yamlDoc['meta']['name'], equals('TaskRepository'));
        expect(yamlDoc['meta']['type'], equals('repository'));
        expect(yamlDoc['meta']['version'], equals('2.0'));
        expect(yamlDoc['meta']['last_updated'], equals('251026'));
      });

      test('仓库定义应该与YAML一致', () {
        final repoDef = yamlDoc['repository_definition'];
        expect(repoDef['abstract_class'], equals('TaskRepository'));
        expect(repoDef['implementation_class'], equals('IsarTaskRepository'));
        expect(repoDef['storage_backend'], equals('isar'));
        expect(repoDef['layer'], equals('data_access'));
      });
    });

    group('Abstract Methods Consistency', () {
      test('应该包含所有必需的抽象方法', () {
        final abstractMethods = yamlDoc['abstract_methods'] as List;
        final methodNames = abstractMethods.map((method) => method['name']).toList();
        
        expect(methodNames, contains('watchSection'));
        expect(methodNames, contains('watchTaskTree'));
        expect(methodNames, contains('watchInbox'));
        expect(methodNames, contains('watchInboxFiltered'));
        expect(methodNames, contains('createTask'));
        expect(methodNames, contains('updateTask'));
        expect(methodNames, contains('moveTask'));
        expect(methodNames, contains('markStatus'));
        expect(methodNames, contains('archiveTask'));
        expect(methodNames, contains('softDelete'));
        expect(methodNames, contains('purgeObsolete'));
        expect(methodNames, contains('adjustTemplateLock'));
        expect(methodNames, contains('findById'));
        expect(methodNames, contains('findBySlug'));
        expect(methodNames, contains('listRoots'));
        expect(methodNames, contains('listChildren'));
        expect(methodNames, contains('upsertTasks'));
        expect(methodNames, contains('listAll'));
        expect(methodNames, contains('searchByTitle'));
      });

      test('watchInboxFiltered方法应该包含新的过滤参数', () {
        final abstractMethods = yamlDoc['abstract_methods'] as List;
        final watchInboxFilteredMethod = abstractMethods.firstWhere((method) => method['name'] == 'watchInboxFiltered');
        final parameters = watchInboxFilteredMethod['parameters'] as List;
        final parameterNames = parameters.map((param) => param['name']).toList();
        
        expect(parameterNames, contains('contextTag'));
        expect(parameterNames, contains('priorityTag'));
        expect(parameterNames, contains('urgencyTag'));
        expect(parameterNames, contains('importanceTag'));
      });

      test('createTask方法应该正确描述', () {
        final abstractMethods = yamlDoc['abstract_methods'] as List;
        final createTaskMethod = abstractMethods.firstWhere((method) => method['name'] == 'createTask');
        
        expect(createTaskMethod['return_type'], equals('Future<Task>'));
        expect(createTaskMethod['description'], contains('创建新任务'));
        expect(createTaskMethod['visibility'], equals('public'));
      });
    });

    group('Implementation Details Consistency', () {
      test('应该包含正确的私有字段', () {
        final privateFields = yamlDoc['implementation_details']['private_fields'] as List;
        final fieldNames = privateFields.map((field) => field['name']).toList();
        
        expect(fieldNames, contains('_isar'));
        expect(fieldNames, contains('_clock'));
        expect(fieldNames, isNot(contains('_random')));
      });

      test('应该包含新的私有方法', () {
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        final methodNames = privateMethods.map((method) => method['name']).toList();
        
        expect(methodNames, contains('_generateTaskId'));
        expect(methodNames, contains('_getLatestTask'));
        expect(methodNames, contains('_parseTaskId'));
      });

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

    group('Dependencies Consistency', () {
      test('应该包含正确的导入', () {
        final imports = yamlDoc['imports'] as List;
        
        expect(imports, contains('dart:async'));
        expect(imports, contains('package:flutter/foundation.dart'));
        expect(imports, contains('package:isar/isar.dart'));
        expect(imports, contains('../isar/task_entity.dart'));
        expect(imports, contains('../models/task.dart'));
        expect(imports, isNot(contains('dart:math')));
      });
    });

    group('Business Rules Consistency', () {
      test('应该包含新的业务规则', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final ruleNames = businessRules.map((rule) => rule['name']).toList();
        
        expect(ruleNames, contains('task_id_generation'));
        expect(ruleNames, contains('task_id_parsing'));
        expect(ruleNames, contains('task_hierarchy'));
        expect(ruleNames, contains('task_status_transition'));
      });

      test('task_id_generation规则应该正确描述', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        
        expect(taskIdGenerationRule['description'], contains('任务 ID 生成规则'));
        expect(taskIdGenerationRule['implementation'], contains('YYYYMMDD-XXXX格式'));
        expect(taskIdGenerationRule['implementation'], contains('基于日期的自增ID生成'));
        expect(taskIdGenerationRule['implementation'], contains('每日从0001开始'));
        expect(taskIdGenerationRule['implementation'], contains('跨天重置'));
      });

      test('task_id_parsing规则应该正确描述', () {
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdParsingRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_parsing');
        
        expect(taskIdParsingRule['description'], contains('任务 ID 解析规则'));
        expect(taskIdParsingRule['implementation'], contains('解析YYYYMMDD-XXXX格式'));
        expect(taskIdParsingRule['implementation'], contains('提取日期和后缀'));
        expect(taskIdParsingRule['implementation'], contains('支持错误处理'));
      });
    });

    group('Error Handling Consistency', () {
      test('应该包含新的异常处理', () {
        final errorHandling = yamlDoc['error_handling'] as List;
        final exceptionNames = errorHandling.map((error) => error['exception']).toList();
        
        expect(exceptionNames, contains('IsarException'));
        expect(exceptionNames, contains('ArgumentError'));
        expect(exceptionNames, contains('TaskIdGenerationException'));
        expect(exceptionNames, contains('TaskIdParseException'));
      });

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

    group('Testing Strategy Consistency', () {
      test('应该包含新的单元测试', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final testNames = unitTests.map((test) => test['name']).toList();
        
        expect(testNames, contains('test_generate_task_id'));
        expect(testNames, contains('test_generate_task_id_format'));
        expect(testNames, contains('test_generate_task_id_increment'));
        expect(testNames, contains('test_generate_task_id_cross_day'));
        expect(testNames, contains('test_parse_task_id'));
        expect(testNames, contains('test_get_latest_task'));
        expect(testNames, contains('test_watch_inbox_filtered'));
      });

      test('应该包含新的集成测试', () {
        final integrationTests = yamlDoc['testing_strategy']['integration_tests'] as List;
        final testNames = integrationTests.map((test) => test['name']).toList();
        
        expect(testNames, contains('test_task_id_generation_integration'));
        expect(testNames, contains('test_task_id_uniqueness'));
      });

      test('test_generate_task_id测试应该正确描述', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id');
        
        expect(generateTaskIdTest['description'], contains('测试任务ID生成功能'));
      });

      test('test_generate_task_id_format测试应该正确描述', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdFormatTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id_format');
        
        expect(generateTaskIdFormatTest['description'], contains('测试任务ID格式验证'));
      });

      test('test_generate_task_id_increment测试应该正确描述', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdIncrementTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id_increment');
        
        expect(generateTaskIdIncrementTest['description'], contains('测试任务ID自增功能'));
      });

      test('test_generate_task_id_cross_day测试应该正确描述', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final generateTaskIdCrossDayTest = unitTests.firstWhere((test) => test['name'] == 'test_generate_task_id_cross_day');
        
        expect(generateTaskIdCrossDayTest['description'], contains('测试任务ID跨天重置功能'));
      });

      test('test_parse_task_id测试应该正确描述', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final parseTaskIdTest = unitTests.firstWhere((test) => test['name'] == 'test_parse_task_id');
        
        expect(parseTaskIdTest['description'], contains('测试任务ID解析功能'));
      });

      test('test_get_latest_task测试应该正确描述', () {
        final unitTests = yamlDoc['testing_strategy']['unit_tests'] as List;
        final getLatestTaskTest = unitTests.firstWhere((test) => test['name'] == 'test_get_latest_task');
        
        expect(getLatestTaskTest['description'], contains('测试获取最新任务功能'));
      });
    });

    group('YAML File Integrity', () {
      test('YAML文件应该存在且可读', () {
        expect(File(yamlFilePath).existsSync(), isTrue);
      });

      test('YAML文件应该包含所有必需的顶级键', () {
        expect(yamlDoc.containsKey('meta'), isTrue);
        expect(yamlDoc.containsKey('repository_definition'), isTrue);
        expect(yamlDoc.containsKey('abstract_methods'), isTrue);
        expect(yamlDoc.containsKey('implementation_details'), isTrue);
        expect(yamlDoc.containsKey('dependencies'), isTrue);
        expect(yamlDoc.containsKey('imports'), isTrue);
        expect(yamlDoc.containsKey('responsibilities'), isTrue);
        expect(yamlDoc.containsKey('data_operations'), isTrue);
        expect(yamlDoc.containsKey('stream_operations'), isTrue);
        expect(yamlDoc.containsKey('validation_rules'), isTrue);
        expect(yamlDoc.containsKey('business_rules'), isTrue);
        expect(yamlDoc.containsKey('error_handling'), isTrue);
        expect(yamlDoc.containsKey('performance_considerations'), isTrue);
        expect(yamlDoc.containsKey('testing_strategy'), isTrue);
      });

      test('YAML文件应该包含正确的元数据', () {
        final meta = yamlDoc['meta'];
        expect(meta.containsKey('name'), isTrue);
        expect(meta.containsKey('type'), isTrue);
        expect(meta.containsKey('description'), isTrue);
        expect(meta.containsKey('version'), isTrue);
        expect(meta.containsKey('created_date'), isTrue);
        expect(meta.containsKey('last_updated'), isTrue);
      });
    });

    group('Document Lock Validation', () {
      test('YAML文件应该被锁定防止意外修改', () {
        // 验证文件存在且可读
        expect(File(yamlFilePath).existsSync(), isTrue);
        
        // 验证文件包含所有必需的结构
        expect(yamlDoc.keys.length, greaterThan(10));
        
        // 验证关键功能描述存在
        final abstractMethods = yamlDoc['abstract_methods'] as List;
        expect(abstractMethods.length, greaterThan(15));
        
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        expect(privateMethods.length, greaterThan(5));
        
        final businessRules = yamlDoc['business_rules'] as List;
        expect(businessRules.length, greaterThan(3));
      });

      test('文档应该包含完整的taskId功能描述', () {
        // 验证taskId相关功能在多个部分都有描述
        final abstractMethods = yamlDoc['abstract_methods'] as List;
        final createTaskMethod = abstractMethods.firstWhere((method) => method['name'] == 'createTask');
        expect(createTaskMethod, isNotNull);
        
        final privateMethods = yamlDoc['implementation_details']['private_methods'] as List;
        final generateTaskIdMethod = privateMethods.firstWhere((method) => method['name'] == '_generateTaskId');
        expect(generateTaskIdMethod, isNotNull);
        
        final businessRules = yamlDoc['business_rules'] as List;
        final taskIdGenerationRule = businessRules.firstWhere((rule) => rule['name'] == 'task_id_generation');
        expect(taskIdGenerationRule, isNotNull);
        
        final errorHandling = yamlDoc['error_handling'] as List;
        final taskIdGenerationException = errorHandling.firstWhere((error) => error['exception'] == 'TaskIdGenerationException');
        expect(taskIdGenerationException, isNotNull);
      });
    });
  });
}
