// ============================================================================
// 📋 YAML 架构文档验证测试 - Repositories
// ============================================================================
//
// ⚠️ 重要说明：本测试文件用于验证代码实现与 YAML 架构文档的一致性
//
// 🎯 测试目的：
// 1. 确保 documents/architecture/repositories/*.yaml 文档准确反映代码实现
// 2. 防止代码变更导致文档与实际不符
// 3. 作为架构文档的"回归测试"，锁定设计规范
//
// ⛔ 禁止行为：
// 1. **绝对不要为了通过测试而修改 YAML 文件**
// 2. **绝对不要删除或跳过失败的测试**
// 3. **绝对不要在未经用户确认的情况下修改 YAML 内容**
//
// ✅ 正确处理流程（当测试失败时）：
// 1. 完成所有测试，收集所有失败信息
// 2. 立即中断操作，不要尝试修复
// 3. 列出所有与 YAML 冲突的修改点
// 4. 询问用户：
//    - 选项 A：修改 YAML 文档以匹配新的代码实现
//    - 选项 B：修改代码以匹配 YAML 文档规范
//    - 选项 C：讨论是否需要调整设计
// 5. 等待用户明确指示后再进行修改
//
// 📝 测试失败意味着：
// - 代码实现偏离了文档规范（可能是有意的改进，也可能是错误）
// - 需要人工判断是更新文档还是修正代码
// - 这是一个设计决策点，不应由 AI 自动处理
//
// ============================================================================

import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:flutter_test/flutter_test.dart';
import 'yaml_test_helper.dart';

class RepositoriesYAMLTest {
  static late Map<String, dynamic> taskRepositoryYaml;
  static late Map<String, dynamic> focusSessionRepositoryYaml;
  static late Map<String, dynamic> tagRepositoryYaml;
  static late Map<String, dynamic> preferenceRepositoryYaml;
  static late Map<String, dynamic> metricRepositoryYaml;
  static late Map<String, dynamic> taskTemplateRepositoryYaml;
  static late Map<String, dynamic> seedRepositoryYaml;

  static Future<void> loadYAMLFiles() async {
    taskRepositoryYaml = yamlToMap(loadYaml(await File('documents/architecture/repositories/task_repository.yaml').readAsString()));
    focusSessionRepositoryYaml = yamlToMap(loadYaml(await File('documents/architecture/repositories/focus_session_repository.yaml').readAsString()));
    tagRepositoryYaml = yamlToMap(loadYaml(await File('documents/architecture/repositories/tag_repository.yaml').readAsString()));
    preferenceRepositoryYaml = yamlToMap(loadYaml(await File('documents/architecture/repositories/preference_repository.yaml').readAsString()));
    metricRepositoryYaml = yamlToMap(loadYaml(await File('documents/architecture/repositories/metric_repository.yaml').readAsString()));
    taskTemplateRepositoryYaml = yamlToMap(loadYaml(await File('documents/architecture/repositories/task_template_repository.yaml').readAsString()));
    seedRepositoryYaml = yamlToMap(loadYaml(await File('documents/architecture/repositories/seed_repository.yaml').readAsString()));
  }

  // 验证 TaskRepository
  static void validateTaskRepository() {
    // 验证 YAML 文件存在
    expect(taskRepositoryYaml, isNotNull, reason: 'TaskRepository YAML file should exist');
    
    // 验证元数据
    expect(taskRepositoryYaml['meta']['name'], equals('TaskRepository'));
    expect(taskRepositoryYaml['meta']['type'], equals('repository'));
    expect(taskRepositoryYaml['meta']['file_path'], equals('lib/data/repositories/task_repository.dart'));
    
    // 验证仓库定义
    final repoDef = yamlToMap(taskRepositoryYaml['repository_definition']);
    expect(repoDef['abstract_class'], equals('TaskRepository'));
    expect(repoDef['implementation_class'], equals('IsarTaskRepository'));
    expect(repoDef['storage_backend'], equals('isar'));
    expect(repoDef['layer'], equals('data_access'));
    
    // 验证抽象方法
    final abstractMethods = yamlToList(taskRepositoryYaml['abstract_methods']);
    expect(abstractMethods.length, greaterThan(10), reason: 'TaskRepository should have many abstract methods');
    
    // 验证关键方法
    final createTaskMethod = abstractMethods.firstWhere((m) => m['name'] == 'createTask');
    expect(createTaskMethod['return_type'], equals('Future<Task>'));
    expect(createTaskMethod['parameters'].length, equals(1));
    
    final watchSectionMethod = abstractMethods.firstWhere((m) => m['name'] == 'watchSection');
    expect(watchSectionMethod['return_type'], equals('Stream<List<Task>>'));
    expect(watchSectionMethod['parameters'].length, equals(1));
    
    final updateTaskMethod = abstractMethods.firstWhere((m) => m['name'] == 'updateTask');
    expect(updateTaskMethod['return_type'], equals('Future<void>'));
    expect(updateTaskMethod['parameters'].length, equals(2));
    
    // 验证实现细节
    final implDetails = yamlToMap(taskRepositoryYaml['implementation_details']);
    expect(implDetails['constructor'], isNotNull, reason: 'TaskRepository should have constructor details');
    expect(implDetails['private_fields'], isNotNull, reason: 'TaskRepository should have private fields');
    expect(implDetails['private_methods'], isNotNull, reason: 'TaskRepository should have private methods');
    
    // 验证依赖
    final dependencies = yamlToList(taskRepositoryYaml['dependencies']);
    expect(dependencies.length, equals(3), reason: 'TaskRepository should have 3 dependencies');
    expect(dependencies.any((d) => d['name'] == 'Isar'), isTrue, reason: 'TaskRepository should depend on Isar');
    expect(dependencies.any((d) => d['name'] == 'TaskEntity'), isTrue, reason: 'TaskRepository should depend on TaskEntity');
    expect(dependencies.any((d) => d['name'] == 'Task'), isTrue, reason: 'TaskRepository should depend on Task');
    
    // 验证导入
    final imports = yamlToList(taskRepositoryYaml['imports']);
    expect(imports, contains('dart:async'));
    expect(imports, contains('dart:math'));
    expect(imports, contains('package:isar/isar.dart'));
    
    // 验证职责
    final responsibilities = yamlToList(taskRepositoryYaml['responsibilities']);
    expect(responsibilities.length, equals(7), reason: 'TaskRepository should have 7 responsibilities');
    expect(responsibilities, contains('任务数据持久化'));
    expect(responsibilities, contains('任务数据查询和过滤'));
    expect(responsibilities, contains('任务状态管理'));
    
    // 验证数据操作
    final dataOps = yamlToMap(taskRepositoryYaml['data_operations']);
    expect(dataOps['create'], isNotNull, reason: 'TaskRepository should have create operations');
    expect(dataOps['read'], isNotNull, reason: 'TaskRepository should have read operations');
    expect(dataOps['update'], isNotNull, reason: 'TaskRepository should have update operations');
    expect(dataOps['delete'], isNotNull, reason: 'TaskRepository should have delete operations');
    
    // 验证流操作
    final streamOps = yamlToList(taskRepositoryYaml['stream_operations']);
    expect(streamOps.length, equals(4), reason: 'TaskRepository should have 4 stream operations');
    expect(streamOps.any((op) => op['name'] == 'watchSection'), isTrue);
    expect(streamOps.any((op) => op['name'] == 'watchTaskTree'), isTrue);
    expect(streamOps.any((op) => op['name'] == 'watchInbox'), isTrue);
    expect(streamOps.any((op) => op['name'] == 'watchInboxFiltered'), isTrue);
    
    // 验证业务规则
    final businessRules = yamlToList(taskRepositoryYaml['business_rules']);
    expect(businessRules.length, equals(3), reason: 'TaskRepository should have 3 business rules');
    expect(businessRules.any((rule) => rule['name'] == 'task_id_generation'), isTrue);
    expect(businessRules.any((rule) => rule['name'] == 'task_hierarchy'), isTrue);
    expect(businessRules.any((rule) => rule['name'] == 'task_status_transition'), isTrue);
    
    // 验证测试策略
    final testingStrategy = yamlToMap(taskRepositoryYaml['testing_strategy']);
    expect(testingStrategy['unit_tests'], isNotNull, reason: 'TaskRepository should have unit tests');
    expect(testingStrategy['integration_tests'], isNotNull, reason: 'TaskRepository should have integration tests');
    expect(testingStrategy['mock_strategy'], isNotNull, reason: 'TaskRepository should have mock strategy');
  }

  // 验证 FocusSessionRepository
  static void validateFocusSessionRepository() {
    expect(focusSessionRepositoryYaml, isNotNull, reason: 'FocusSessionRepository YAML file should exist');
    
    final repoDef = yamlToMap(focusSessionRepositoryYaml['repository_definition']);
    expect(repoDef['abstract_class'], equals('FocusSessionRepository'));
    expect(repoDef['implementation_class'], equals('IsarFocusSessionRepository'));
    expect(repoDef['storage_backend'], equals('isar'));
    expect(repoDef['layer'], equals('data_access'));
    
    final abstractMethods = yamlToList(focusSessionRepositoryYaml['abstract_methods']);
    expect(abstractMethods.length, equals(5), reason: 'FocusSessionRepository should have 5 abstract methods');
    
    final startSessionMethod = abstractMethods.firstWhere((m) => m['name'] == 'startSession');
    expect(startSessionMethod['return_type'], equals('Future<FocusSession>'));
    expect(startSessionMethod['parameters'].length, equals(3));
    
    final endSessionMethod = abstractMethods.firstWhere((m) => m['name'] == 'endSession');
    expect(endSessionMethod['return_type'], equals('Future<void>'));
    expect(endSessionMethod['parameters'].length, equals(4));
    
    final watchActiveSessionMethod = abstractMethods.firstWhere((m) => m['name'] == 'watchActiveSession');
    expect(watchActiveSessionMethod['return_type'], equals('Stream<FocusSession?>'));
    expect(watchActiveSessionMethod['parameters'].length, equals(1));
  }

  // 验证 TagRepository
  static void validateTagRepository() {
    expect(tagRepositoryYaml, isNotNull, reason: 'TagRepository YAML file should exist');
    
    final repoDef = yamlToMap(tagRepositoryYaml['repository_definition']);
    expect(repoDef['abstract_class'], equals('TagRepository'));
    expect(repoDef['implementation_class'], equals('IsarTagRepository'));
    expect(repoDef['storage_backend'], equals('isar'));
    expect(repoDef['layer'], equals('data_access'));
    
    final abstractMethods = yamlToList(tagRepositoryYaml['abstract_methods']);
    expect(abstractMethods.length, equals(3), reason: 'TagRepository should have 3 abstract methods');
    
    final ensureSeededMethod = abstractMethods.firstWhere((m) => m['name'] == 'ensureSeeded');
    expect(ensureSeededMethod['return_type'], equals('Future<void>'));
    expect(ensureSeededMethod['parameters'].length, equals(1));
    
    final listByKindMethod = abstractMethods.firstWhere((m) => m['name'] == 'listByKind');
    expect(listByKindMethod['return_type'], equals('Future<List<Tag>>'));
    expect(listByKindMethod['parameters'].length, equals(1));
    
    final findBySlugMethod = abstractMethods.firstWhere((m) => m['name'] == 'findBySlug');
    expect(findBySlugMethod['return_type'], equals('Future<Tag?>'));
    expect(findBySlugMethod['parameters'].length, equals(1));
  }

  // 验证 PreferenceRepository
  static void validatePreferenceRepository() {
    expect(preferenceRepositoryYaml, isNotNull, reason: 'PreferenceRepository YAML file should exist');
    
    final repoDef = yamlToMap(preferenceRepositoryYaml['repository_definition']);
    expect(repoDef['abstract_class'], equals('PreferenceRepository'));
    expect(repoDef['implementation_class'], equals('IsarPreferenceRepository'));
    expect(repoDef['storage_backend'], equals('isar'));
    expect(repoDef['layer'], equals('data_access'));
    
    final abstractMethods = yamlToList(preferenceRepositoryYaml['abstract_methods']);
    expect(abstractMethods.length, equals(3), reason: 'PreferenceRepository should have 3 abstract methods');
    
    final watchMethod = abstractMethods.firstWhere((m) => m['name'] == 'watch');
    expect(watchMethod['return_type'], equals('Stream<Preference>'));
    expect(watchMethod['parameters'].length, equals(0));
    
    final loadMethod = abstractMethods.firstWhere((m) => m['name'] == 'load');
    expect(loadMethod['return_type'], equals('Future<Preference>'));
    expect(loadMethod['parameters'].length, equals(0));
    
    final updateMethod = abstractMethods.firstWhere((m) => m['name'] == 'update');
    expect(updateMethod['return_type'], equals('Future<void>'));
    expect(updateMethod['parameters'].length, equals(1));
  }

  // 验证 MetricRepository
  static void validateMetricRepository() {
    expect(metricRepositoryYaml, isNotNull, reason: 'MetricRepository YAML file should exist');
    
    final repoDef = yamlToMap(metricRepositoryYaml['repository_definition']);
    expect(repoDef['abstract_class'], equals('MetricRepository'));
    expect(repoDef['implementation_class'], equals('InMemoryMetricRepository'));
    expect(repoDef['storage_backend'], equals('memory'));
    expect(repoDef['layer'], equals('data_access'));
    
    final abstractMethods = yamlToList(metricRepositoryYaml['abstract_methods']);
    expect(abstractMethods.length, equals(3), reason: 'MetricRepository should have 3 abstract methods');
    
    final recomputeMethod = abstractMethods.firstWhere((m) => m['name'] == 'recompute');
    expect(recomputeMethod['return_type'], equals('Future<MetricSnapshot>'));
    expect(recomputeMethod['parameters'].length, equals(2));
    
    final watchLatestMethod = abstractMethods.firstWhere((m) => m['name'] == 'watchLatest');
    expect(watchLatestMethod['return_type'], equals('Stream<MetricSnapshot?>'));
    expect(watchLatestMethod['parameters'].length, equals(0));
    
    final invalidateMethod = abstractMethods.firstWhere((m) => m['name'] == 'invalidate');
    expect(invalidateMethod['return_type'], equals('Future<void>'));
    expect(invalidateMethod['parameters'].length, equals(0));
  }

  // 验证 TaskTemplateRepository
  static void validateTaskTemplateRepository() {
    expect(taskTemplateRepositoryYaml, isNotNull, reason: 'TaskTemplateRepository YAML file should exist');
    
    final repoDef = yamlToMap(taskTemplateRepositoryYaml['repository_definition']);
    expect(repoDef['abstract_class'], equals('TaskTemplateRepository'));
    expect(repoDef['implementation_class'], equals('IsarTaskTemplateRepository'));
    expect(repoDef['storage_backend'], equals('isar'));
    expect(repoDef['layer'], equals('data_access'));
    
    final abstractMethods = yamlToList(taskTemplateRepositoryYaml['abstract_methods']);
    expect(abstractMethods.length, equals(9), reason: 'TaskTemplateRepository should have 9 abstract methods');
    
    final createTemplateMethod = abstractMethods.firstWhere((m) => m['name'] == 'createTemplate');
    expect(createTemplateMethod['return_type'], equals('Future<TaskTemplate>'));
    expect(createTemplateMethod['parameters'].length, equals(1));
    
    final searchMethod = abstractMethods.firstWhere((m) => m['name'] == 'search');
    expect(searchMethod['return_type'], equals('Future<List<TaskTemplate>>'));
    expect(searchMethod['parameters'].length, equals(2));
    
    final updateTemplateMethod = abstractMethods.firstWhere((m) => m['name'] == 'updateTemplate');
    expect(updateTemplateMethod['return_type'], equals('Future<void>'));
    expect(updateTemplateMethod['parameters'].length, equals(2));
  }

  // 验证 SeedRepository
  static void validateSeedRepository() {
    expect(seedRepositoryYaml, isNotNull, reason: 'SeedRepository YAML file should exist');
    
    final repoDef = yamlToMap(seedRepositoryYaml['repository_definition']);
    expect(repoDef['abstract_class'], equals('SeedRepository'));
    expect(repoDef['implementation_class'], equals('IsarSeedRepository'));
    expect(repoDef['storage_backend'], equals('isar'));
    expect(repoDef['layer'], equals('data_access'));
    
    final abstractMethods = yamlToList(seedRepositoryYaml['abstract_methods']);
    expect(abstractMethods.length, equals(3), reason: 'SeedRepository should have 3 abstract methods');
    
    final importSeedDataMethod = abstractMethods.firstWhere((m) => m['name'] == 'importSeedData');
    expect(importSeedDataMethod['return_type'], equals('Future<void>'));
    expect(importSeedDataMethod['parameters'].length, equals(1));
    
    final checkImportStatusMethod = abstractMethods.firstWhere((m) => m['name'] == 'checkImportStatus');
    expect(checkImportStatusMethod['return_type'], equals('Future<bool>'));
    expect(checkImportStatusMethod['parameters'].length, equals(1));
    
    final getImportHistoryMethod = abstractMethods.firstWhere((m) => m['name'] == 'getImportHistory');
    expect(getImportHistoryMethod['return_type'], equals('Future<List<SeedImportLog>>'));
    expect(getImportHistoryMethod['parameters'].length, equals(0));
  }

  // 验证所有 Repository 的一致性
  static void validateAllRepositoriesConsistency() {
    // 验证所有 Repository 都有正确的元数据
    final allYamls = [taskRepositoryYaml, focusSessionRepositoryYaml, tagRepositoryYaml, preferenceRepositoryYaml, metricRepositoryYaml, taskTemplateRepositoryYaml, seedRepositoryYaml];
    
    for (final yaml in allYamls) {
      expect(yaml['meta'], isNotNull, reason: 'All repositories should have meta section');
      expect(yaml['meta']['name'], isNotNull, reason: 'All repositories should have name');
      expect(yaml['meta']['type'], equals('repository'), reason: 'All repositories should have type repository');
      expect(yaml['meta']['file_path'], isNotNull, reason: 'All repositories should have file_path');
      expect(yaml['meta']['description'], isNotNull, reason: 'All repositories should have description');
      
      expect(yaml['repository_definition'], isNotNull, reason: 'All repositories should have repository_definition');
      expect(yaml['repository_definition']['abstract_class'], isNotNull, reason: 'All repositories should have abstract_class');
      expect(yaml['repository_definition']['implementation_class'], isNotNull, reason: 'All repositories should have implementation_class');
      expect(yaml['repository_definition']['storage_backend'], isNotNull, reason: 'All repositories should have storage_backend');
      expect(yaml['repository_definition']['layer'], equals('data_access'), reason: 'All repositories should have layer data_access');
      
      expect(yaml['abstract_methods'], isNotNull, reason: 'All repositories should have abstract_methods');
      expect(yaml['abstract_methods'], isA<List>(), reason: 'All repositories should have abstract_methods as list');
      expect((yaml['abstract_methods'] as List).isNotEmpty, isTrue, reason: 'All repositories should have non-empty abstract_methods');
      
      expect(yaml['implementation_details'], isNotNull, reason: 'All repositories should have implementation_details');
      expect(yaml['implementation_details']['constructor'], isNotNull, reason: 'All repositories should have constructor details');
      
      expect(yaml['dependencies'], isNotNull, reason: 'All repositories should have dependencies');
      expect(yaml['dependencies'], isA<List>(), reason: 'All repositories should have dependencies as list');
      
      expect(yaml['imports'], isNotNull, reason: 'All repositories should have imports');
      expect(yaml['imports'], isA<List>(), reason: 'All repositories should have imports as list');
      
      expect(yaml['responsibilities'], isNotNull, reason: 'All repositories should have responsibilities');
      expect(yaml['responsibilities'], isA<List>(), reason: 'All repositories should have responsibilities as list');
      expect((yaml['responsibilities'] as List).isNotEmpty, isTrue, reason: 'All repositories should have non-empty responsibilities');
      
      expect(yaml['data_operations'], isNotNull, reason: 'All repositories should have data_operations');
      expect(yaml['data_operations'], isA<Map>(), reason: 'All repositories should have data_operations as map');
      
      expect(yaml['testing_strategy'], isNotNull, reason: 'All repositories should have testing_strategy');
      expect(yaml['testing_strategy'], isA<Map>(), reason: 'All repositories should have testing_strategy as map');
    }
  }
}

void main() {
  group('Repositories YAML Tests', () {
    setUpAll(() async {
      await RepositoriesYAMLTest.loadYAMLFiles();
    });

    test('TaskRepository should match YAML definition', () {
      RepositoriesYAMLTest.validateTaskRepository();
    });

    test('FocusSessionRepository should match YAML definition', () {
      RepositoriesYAMLTest.validateFocusSessionRepository();
    });

    test('TagRepository should match YAML definition', () {
      RepositoriesYAMLTest.validateTagRepository();
    });

    test('PreferenceRepository should match YAML definition', () {
      RepositoriesYAMLTest.validatePreferenceRepository();
    });

    test('MetricRepository should match YAML definition', () {
      RepositoriesYAMLTest.validateMetricRepository();
    });

    test('TaskTemplateRepository should match YAML definition', () {
      RepositoriesYAMLTest.validateTaskTemplateRepository();
    });

    test('SeedRepository should match YAML definition', () {
      RepositoriesYAMLTest.validateSeedRepository();
    });

    test('All repositories should have consistent structure', () {
      RepositoriesYAMLTest.validateAllRepositoriesConsistency();
    });
  });
}
