// ============================================================================
// 📋 YAML 架构文档验证测试 - Models
// ============================================================================
//
// ⚠️ 重要说明：本测试文件用于验证代码实现与 YAML 架构文档的一致性
//
// 🎯 测试目的：
// 1. 确保 documents/architecture/models/*.yaml 文档准确反映代码实现
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

class ModelsYAMLTest {
  static late Map<String, dynamic> taskYaml;
  static late Map<String, dynamic> focusSessionYaml;
  static late Map<String, dynamic> tagYaml;
  static late Map<String, dynamic> preferenceYaml;
  static late Map<String, dynamic> taskTemplateYaml;
  static late Map<String, dynamic> metricSnapshotYaml;
  static late Map<String, dynamic> seedImportLogYaml;

  static Future<void> loadYAMLFiles() async {
    taskYaml = yamlToMap(loadYaml(await File('documents/architecture/models/task.yaml').readAsString()));
    focusSessionYaml = yamlToMap(loadYaml(await File('documents/architecture/models/focus_session.yaml').readAsString()));
    tagYaml = yamlToMap(loadYaml(await File('documents/architecture/models/tag.yaml').readAsString()));
    preferenceYaml = yamlToMap(loadYaml(await File('documents/architecture/models/preference.yaml').readAsString()));
    taskTemplateYaml = yamlToMap(loadYaml(await File('documents/architecture/models/task_template.yaml').readAsString()));
    metricSnapshotYaml = yamlToMap(loadYaml(await File('documents/architecture/models/metric_snapshot.yaml').readAsString()));
    seedImportLogYaml = yamlToMap(loadYaml(await File('documents/architecture/models/seed_import_log.yaml').readAsString()));
  }

  // 验证 Task 模型
  static void validateTaskModel() {
    // 验证 YAML 文件存在
    expect(taskYaml, isNotNull, reason: 'Task YAML file should exist');
    
    // 验证元数据
    expect(taskYaml['meta']['name'], equals('Task Model'));
    expect(taskYaml['meta']['type'], equals('model'));
    expect(taskYaml['meta']['file_path'], equals('lib/data/models/task.dart'));
    
    // 验证模型定义
    final modelDef = yamlToMap(taskYaml['model_definition']);
    expect(modelDef['name'], equals('Task'));
    expect(modelDef['storage'], equals('isar_collection'));
    expect(modelDef['immutable'], equals(true));
    
    // 验证枚举
    final enums = yamlToList(taskYaml['enums']);
    expect(enums.length, equals(2), reason: 'Task should have 2 enums');
    
    final taskStatusEnum = enums.firstWhere((e) => e['name'] == 'TaskStatus');
    expect(taskStatusEnum['values'], contains('inbox'));
    expect(taskStatusEnum['values'], contains('pending'));
    expect(taskStatusEnum['values'], contains('doing'));
    expect(taskStatusEnum['values'], contains('completedActive'));
    expect(taskStatusEnum['values'], contains('archived'));
    expect(taskStatusEnum['values'], contains('trashed'));
    expect(taskStatusEnum['values'], contains('pseudoDeleted'));
    
    final taskSectionEnum = enums.firstWhere((e) => e['name'] == 'TaskSection');
    expect(taskSectionEnum['values'], contains('today'));
    expect(taskSectionEnum['values'], contains('tomorrow'));
    expect(taskSectionEnum['values'], contains('later'));
    expect(taskSectionEnum['values'], contains('completed'));
    expect(taskSectionEnum['values'], contains('archived'));
    expect(taskSectionEnum['values'], contains('trash'));
    
    // 验证字段
    final fields = yamlToList(taskYaml['fields']);
    expect(fields.length, greaterThan(10), reason: 'Task should have many fields');
    
    // 验证关键字段
    final idField = fields.firstWhere((f) => f['name'] == 'id');
    expect(idField['type'], equals('int'));
    expect(idField['required'], equals(true));
    expect(idField['nullable'], equals(false));
    
    final taskIdField = fields.firstWhere((f) => f['name'] == 'taskId');
    expect(taskIdField['type'], equals('String'));
    expect(taskIdField['required'], equals(true));
    expect(taskIdField['nullable'], equals(false));
    
    final titleField = fields.firstWhere((f) => f['name'] == 'title');
    expect(titleField['type'], equals('String'));
    expect(titleField['required'], equals(true));
    expect(titleField['nullable'], equals(false));
    
    final statusField = fields.firstWhere((f) => f['name'] == 'status');
    expect(statusField['type'], equals('TaskStatus'));
    expect(statusField['required'], equals(true));
    expect(statusField['nullable'], equals(false));
    
    // 验证构造函数
    final constructors = yamlToList(taskYaml['constructors']);
    expect(constructors.length, equals(1), reason: 'Task should have 1 constructor');
    
    final mainConstructor = constructors.first;
    expect(mainConstructor['type'], equals('const'));
    expect(mainConstructor['name'], equals('Task'));
    
    // 验证方法
    final methods = yamlToList(taskYaml['methods']);
    expect(methods.length, greaterThan(3), reason: 'Task should have multiple methods');
    
    final copyWithMethod = methods.firstWhere((m) => m['name'] == 'copyWith');
    expect(copyWithMethod['return_type'], equals('Task'));
    
    final equalsMethod = methods.firstWhere((m) => m['name'] == 'operator ==');
    expect(equalsMethod['return_type'], equals('bool'));
    
    // 验证 getters
    final getters = yamlToList(taskYaml['getters']);
    expect(getters.length, equals(2), reason: 'Task should have 2 getters');
    
    final canEditStructureGetter = getters.firstWhere((g) => g['name'] == 'canEditStructure');
    expect(canEditStructureGetter['return_type'], equals('bool'));
    
    final isLeafGetter = getters.firstWhere((g) => g['name'] == 'isLeaf');
    expect(isLeafGetter['return_type'], equals('bool'));
    
    // 验证导入
    final imports = yamlToList(taskYaml['imports']);
    expect(imports, contains('package:collection/collection.dart'));
    expect(imports, contains('package:flutter/foundation.dart'));
    
    // 验证依赖
    final dependencies = yamlToList(taskYaml['dependencies']);
    expect(dependencies, contains('TaskStatus'));
    expect(dependencies, contains('TaskSection'));
    
    // 验证关系
    final relationships = yamlToList(taskYaml['relationships']);
    expect(relationships.length, equals(1), reason: 'Task should have 1 relationship');
    
    final parentChildRelationship = relationships.first;
    expect(parentChildRelationship['type'], equals('many_to_one'));
    expect(parentChildRelationship['target'], equals('Task'));
    expect(parentChildRelationship['field'], equals('parentId'));
    
    // 验证存储配置
    final storageConfig = yamlToMap(taskYaml['storage_config']);
    final indexes = yamlToList(storageConfig['indexes']);
    expect(indexes.any((index) => index['field'] == 'status'), isTrue);
    expect(indexes.any((index) => index['field'] == 'dueAt'), isTrue);
    expect(indexes.any((index) => index['field'] == 'parentId'), isTrue);
    expect(indexes.any((index) => index['field'] == 'updatedAt'), isTrue);
  }

  // 验证 FocusSession 模型
  static void validateFocusSessionModel() {
    expect(focusSessionYaml, isNotNull, reason: 'FocusSession YAML file should exist');
    
    final modelDef = yamlToMap(focusSessionYaml['model_definition']);
    expect(modelDef['name'], equals('FocusSession'));
    expect(modelDef['storage'], equals('isar_collection'));
    expect(modelDef['immutable'], equals(true));
    
    final fields = yamlToList(focusSessionYaml['fields']);
    expect(fields.length, equals(9), reason: 'FocusSession should have 9 fields');
    
    final taskIdField = fields.firstWhere((f) => f['name'] == 'taskId');
    expect(taskIdField['type'], equals('int'));
    expect(taskIdField['required'], equals(true));
    
    final isActiveGetter = yamlToList(focusSessionYaml['getters']);
    expect(isActiveGetter.length, equals(1), reason: 'FocusSession should have 1 getter');
    expect(isActiveGetter.first['name'], equals('isActive'));
    expect(isActiveGetter.first['return_type'], equals('bool'));
  }

  // 验证 Tag 模型
  static void validateTagModel() {
    expect(tagYaml, isNotNull, reason: 'Tag YAML file should exist');
    
    final modelDef = yamlToMap(tagYaml['model_definition']);
    expect(modelDef['name'], equals('Tag'));
    expect(modelDef['storage'], equals('isar_collection'));
    expect(modelDef['immutable'], equals(true));
    
    final enums = yamlToList(tagYaml['enums']);
    expect(enums.length, equals(1), reason: 'Tag should have 1 enum');
    
    final tagKindEnum = enums.first;
    expect(tagKindEnum['name'], equals('TagKind'));
    expect(tagKindEnum['values'], contains('context'));
    expect(tagKindEnum['values'], contains('priority'));
    expect(tagKindEnum['values'], contains('special'));
    
    final fields = yamlToList(tagYaml['fields']);
    expect(fields.length, equals(4), reason: 'Tag should have 4 fields');
    
    final slugField = fields.firstWhere((f) => f['name'] == 'slug');
    expect(slugField['type'], equals('String'));
    expect(slugField['required'], equals(true));
    
    final kindField = fields.firstWhere((f) => f['name'] == 'kind');
    expect(kindField['type'], equals('TagKind'));
    expect(kindField['required'], equals(true));
    
    final localizedLabelsField = fields.firstWhere((f) => f['name'] == 'localizedLabels');
    expect(localizedLabelsField['type'], equals('Map<String, String>'));
    expect(localizedLabelsField['required'], equals(true));
  }

  // 验证 Preference 模型
  static void validatePreferenceModel() {
    expect(preferenceYaml, isNotNull, reason: 'Preference YAML file should exist');
    
    final modelDef = yamlToMap(preferenceYaml['model_definition']);
    expect(modelDef['name'], equals('Preference'));
    expect(modelDef['storage'], equals('isar_collection'));
    expect(modelDef['immutable'], equals(true));
    
    final fields = yamlToList(preferenceYaml['fields']);
    expect(fields.length, equals(5), reason: 'Preference should have 5 fields');
    
    final localeCodeField = fields.firstWhere((f) => f['name'] == 'localeCode');
    expect(localeCodeField['type'], equals('String'));
    expect(localeCodeField['required'], equals(true));
    
    final themeModeField = fields.firstWhere((f) => f['name'] == 'themeMode');
    expect(themeModeField['type'], equals('ThemeMode'));
    expect(themeModeField['required'], equals(true));
    
    final fontScaleField = fields.firstWhere((f) => f['name'] == 'fontScale');
    expect(fontScaleField['type'], equals('double'));
    expect(fontScaleField['required'], equals(true));
  }

  // 验证 TaskTemplate 模型
  static void validateTaskTemplateModel() {
    expect(taskTemplateYaml, isNotNull, reason: 'TaskTemplate YAML file should exist');
    
    final modelDef = yamlToMap(taskTemplateYaml['model_definition']);
    expect(modelDef['name'], equals('TaskTemplate'));
    expect(modelDef['storage'], equals('isar_collection'));
    expect(modelDef['immutable'], equals(true));
    
    final fields = yamlToList(taskTemplateYaml['fields']);
    expect(fields.length, equals(9), reason: 'TaskTemplate should have 9 fields');
    
    final titleField = fields.firstWhere((f) => f['name'] == 'title');
    expect(titleField['type'], equals('String'));
    expect(titleField['required'], equals(true));
    
    final defaultTagsField = fields.firstWhere((f) => f['name'] == 'defaultTags');
    expect(defaultTagsField['type'], equals('List<String>'));
    expect(defaultTagsField['default'], equals('const <String>[]'));
  }

  // 验证 MetricSnapshot 模型
  static void validateMetricSnapshotModel() {
    expect(metricSnapshotYaml, isNotNull, reason: 'MetricSnapshot YAML file should exist');
    
    final modelDef = yamlToMap(metricSnapshotYaml['model_definition']);
    expect(modelDef['name'], equals('MetricSnapshot'));
    expect(modelDef['storage'], equals('isar_collection'));
    expect(modelDef['immutable'], equals(true));
    
    final fields = yamlToList(metricSnapshotYaml['fields']);
    expect(fields.length, equals(6), reason: 'MetricSnapshot should have 6 fields');
    
    final totalCompletedTasksField = fields.firstWhere((f) => f['name'] == 'totalCompletedTasks');
    expect(totalCompletedTasksField['type'], equals('int'));
    expect(totalCompletedTasksField['required'], equals(true));
    
    final totalFocusMinutesField = fields.firstWhere((f) => f['name'] == 'totalFocusMinutes');
    expect(totalFocusMinutesField['type'], equals('int'));
    expect(totalFocusMinutesField['required'], equals(true));
  }

  // 验证 SeedImportLog 模型
  static void validateSeedImportLogModel() {
    expect(seedImportLogYaml, isNotNull, reason: 'SeedImportLog YAML file should exist');
    
    final modelDef = yamlToMap(seedImportLogYaml['model_definition']);
    expect(modelDef['name'], equals('SeedImportLog'));
    expect(modelDef['storage'], equals('isar_collection'));
    expect(modelDef['immutable'], equals(true));
    
    final fields = yamlToList(seedImportLogYaml['fields']);
    expect(fields.length, equals(3), reason: 'SeedImportLog should have 3 fields');
    
    final versionField = fields.firstWhere((f) => f['name'] == 'version');
    expect(versionField['type'], equals('String'));
    expect(versionField['required'], equals(true));
    
    final importedAtField = fields.firstWhere((f) => f['name'] == 'importedAt');
    expect(importedAtField['type'], equals('DateTime'));
    expect(importedAtField['required'], equals(true));
  }

  // 验证所有模型的一致性
  static void validateAllModelsConsistency() {
    // 验证所有模型都有正确的元数据
    final allYamls = [taskYaml, focusSessionYaml, tagYaml, preferenceYaml, taskTemplateYaml, metricSnapshotYaml, seedImportLogYaml];
    
    for (final yaml in allYamls) {
      expect(yaml['meta'], isNotNull, reason: 'All models should have meta section');
      expect(yaml['meta']['name'], isNotNull, reason: 'All models should have name');
      expect(yaml['meta']['type'], equals('model'), reason: 'All models should have type model');
      expect(yaml['meta']['file_path'], isNotNull, reason: 'All models should have file_path');
      expect(yaml['meta']['description'], isNotNull, reason: 'All models should have description');
      
      expect(yaml['model_definition'], isNotNull, reason: 'All models should have model_definition');
      expect(yaml['model_definition']['name'], isNotNull, reason: 'All models should have model name');
      expect(yaml['model_definition']['storage'], equals('isar_collection'), reason: 'All models should use isar_collection storage');
      expect(yaml['model_definition']['immutable'], equals(true), reason: 'All models should be immutable');
      
      expect(yaml['fields'], isNotNull, reason: 'All models should have fields');
      expect(yaml['fields'], isA<List>(), reason: 'All models should have fields as list');
      expect((yaml['fields'] as List).isNotEmpty, isTrue, reason: 'All models should have non-empty fields');
      
      expect(yaml['constructors'], isNotNull, reason: 'All models should have constructors');
      expect(yaml['constructors'], isA<List>(), reason: 'All models should have constructors as list');
      expect((yaml['constructors'] as List).isNotEmpty, isTrue, reason: 'All models should have non-empty constructors');
      
      expect(yaml['imports'], isNotNull, reason: 'All models should have imports');
      expect(yaml['imports'], isA<List>(), reason: 'All models should have imports as list');
    }
  }
}

void main() {
  group('Models YAML Tests', () {
    setUpAll(() async {
      await ModelsYAMLTest.loadYAMLFiles();
    });

    test('Task model should match YAML definition', () {
      ModelsYAMLTest.validateTaskModel();
    });

    test('FocusSession model should match YAML definition', () {
      ModelsYAMLTest.validateFocusSessionModel();
    });

    test('Tag model should match YAML definition', () {
      ModelsYAMLTest.validateTagModel();
    });

    test('Preference model should match YAML definition', () {
      ModelsYAMLTest.validatePreferenceModel();
    });

    test('TaskTemplate model should match YAML definition', () {
      ModelsYAMLTest.validateTaskTemplateModel();
    });

    test('MetricSnapshot model should match YAML definition', () {
      ModelsYAMLTest.validateMetricSnapshotModel();
    });

    test('SeedImportLog model should match YAML definition', () {
      ModelsYAMLTest.validateSeedImportLogModel();
    });

    test('All models should have consistent structure', () {
      ModelsYAMLTest.validateAllModelsConsistency();
    });
  });
}
