import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:flutter_test/flutter_test.dart';
import 'yaml_test_helper.dart';

class ServicesYAMLTest {
  static late Map<String, dynamic> taskServiceYaml;
  static late Map<String, dynamic> focusFlowServiceYaml;
  static late Map<String, dynamic> metricOrchestratorYaml;
  static late Map<String, dynamic> preferenceServiceYaml;
  static late Map<String, dynamic> taskHierarchyServiceYaml;
  static late Map<String, dynamic> taskTemplateServiceYaml;
  static late Map<String, dynamic> seedImportServiceYaml;

  static Future<void> loadYAMLFiles() async {
    taskServiceYaml = yamlToMap(loadYaml(await File('documents/architecture/services/task_service.yaml').readAsString()));
    focusFlowServiceYaml = yamlToMap(loadYaml(await File('documents/architecture/services/focus_flow_service.yaml').readAsString()));
    metricOrchestratorYaml = yamlToMap(loadYaml(await File('documents/architecture/services/metric_orchestrator.yaml').readAsString()));
    preferenceServiceYaml = yamlToMap(loadYaml(await File('documents/architecture/services/preference_service.yaml').readAsString()));
    taskHierarchyServiceYaml = yamlToMap(loadYaml(await File('documents/architecture/services/task_hierarchy_service.yaml').readAsString()));
    taskTemplateServiceYaml = yamlToMap(loadYaml(await File('documents/architecture/services/task_template_service.yaml').readAsString()));
    seedImportServiceYaml = yamlToMap(loadYaml(await File('documents/architecture/services/seed_import_service.yaml').readAsString()));
  }

  // 验证 TaskService
  static void validateTaskService() {
    // 验证 YAML 文件存在
    expect(taskServiceYaml, isNotNull, reason: 'TaskService YAML file should exist');
    
    // 验证元数据
    expect(taskServiceYaml['meta']['name'], equals('TaskService'));
    expect(taskServiceYaml['meta']['type'], equals('service'));
    expect(taskServiceYaml['meta']['file_path'], equals('lib/core/services/task_service.dart'));
    
    // 验证服务定义
    final serviceDef = yamlToMap(taskServiceYaml['service_definition']);
    expect(serviceDef['name'], equals('TaskService'));
    expect(serviceDef['layer'], equals('business_logic'));
    expect(serviceDef['pattern'], equals('service'));
    expect(serviceDef['singleton'], equals(false));
    
    // 验证构造函数
    final constructor = yamlToMap(taskServiceYaml['constructor']);
    expect(constructor['parameters'], isNotNull, reason: 'TaskService should have constructor parameters');
    expect(constructor['dependencies'], isNotNull, reason: 'TaskService should have dependencies');
    
    // 验证公共方法
    final publicMethods = yamlToList(taskServiceYaml['public_methods']);
    expect(publicMethods.length, greaterThan(8), reason: 'TaskService should have many public methods');
    
    // 验证关键方法
    final captureInboxTaskMethod = publicMethods.firstWhere((m) => m['name'] == 'captureInboxTask');
    expect(captureInboxTaskMethod['return_type'], equals('Future<Task>'));
    expect(captureInboxTaskMethod['parameters'].length, equals(2));
    
    final planTaskMethod = publicMethods.firstWhere((m) => m['name'] == 'planTask');
    expect(planTaskMethod['return_type'], equals('Future<void>'));
    expect(planTaskMethod['parameters'].length, equals(3));
    
    final startTaskMethod = publicMethods.firstWhere((m) => m['name'] == 'startTask');
    expect(startTaskMethod['return_type'], equals('Future<void>'));
    expect(startTaskMethod['parameters'].length, equals(1));
    
    final completeTaskMethod = publicMethods.firstWhere((m) => m['name'] == 'completeTask');
    expect(completeTaskMethod['return_type'], equals('Future<void>'));
    expect(completeTaskMethod['parameters'].length, equals(1));
    
    // 验证私有方法
    final privateMethods = yamlToList(taskServiceYaml['private_methods']);
    expect(privateMethods.length, equals(2), reason: 'TaskService should have 2 private methods');
    
    final normalizeDueDateMethod = privateMethods.firstWhere((m) => m['name'] == '_normalizeDueDate');
    expect(normalizeDueDateMethod['return_type'], equals('DateTime'));
    expect(normalizeDueDateMethod['parameters'].length, equals(1));
    
    final validateTaskOperationMethod = privateMethods.firstWhere((m) => m['name'] == '_validateTaskOperation');
    expect(validateTaskOperationMethod['return_type'], equals('void'));
    expect(validateTaskOperationMethod['parameters'].length, equals(2));
    
    // 验证字段
    final fields = yamlToList(taskServiceYaml['fields']);
    expect(fields.length, equals(4), reason: 'TaskService should have 4 fields');
    
    final tasksField = fields.firstWhere((f) => f['name'] == '_tasks');
    expect(tasksField['type'], equals('TaskRepository'));
    expect(tasksField['final'], equals(true));
    
    final tagsField = fields.firstWhere((f) => f['name'] == '_tags');
    expect(tagsField['type'], equals('TagRepository'));
    expect(tagsField['final'], equals(true));
    
    final metricOrchestratorField = fields.firstWhere((f) => f['name'] == '_metricOrchestrator');
    expect(metricOrchestratorField['type'], equals('MetricOrchestrator'));
    expect(metricOrchestratorField['final'], equals(true));
    
    final clockField = fields.firstWhere((f) => f['name'] == '_clock');
    expect(clockField['type'], equals('DateTime Function()'));
    expect(clockField['final'], equals(true));
    
    // 验证依赖
    final dependencies = yamlToList(taskServiceYaml['dependencies']);
    expect(dependencies.length, equals(5), reason: 'TaskService should have 5 dependencies');
    expect(dependencies.any((d) => d['name'] == 'TaskRepository'), isTrue, reason: 'TaskService should depend on TaskRepository');
    expect(dependencies.any((d) => d['name'] == 'TagRepository'), isTrue, reason: 'TaskService should depend on TagRepository');
    expect(dependencies.any((d) => d['name'] == 'MetricOrchestrator'), isTrue, reason: 'TaskService should depend on MetricOrchestrator');
    
    // 验证职责
    final responsibilities = yamlToList(taskServiceYaml['responsibilities']);
    expect(responsibilities.length, equals(6), reason: 'TaskService should have 6 responsibilities');
    expect(responsibilities, contains('任务业务逻辑处理'));
    expect(responsibilities, contains('任务状态管理'));
    expect(responsibilities, contains('任务数据协调'));
    
    // 验证业务操作
    final businessOps = yamlToMap(taskServiceYaml['business_operations']);
    expect(businessOps['create'], isNotNull, reason: 'TaskService should have create operations');
    expect(businessOps['read'], isNotNull, reason: 'TaskService should have read operations');
    expect(businessOps['update'], isNotNull, reason: 'TaskService should have update operations');
    expect(businessOps['delete'], isNotNull, reason: 'TaskService should have delete operations');
    
    // 验证业务规则
    final businessRules = yamlToList(taskServiceYaml['business_rules']);
    expect(businessRules.length, equals(3), reason: 'TaskService should have 3 business rules');
    expect(businessRules.any((rule) => rule['name'] == 'task_status_transition'), isTrue);
    expect(businessRules.any((rule) => rule['name'] == 'task_editing_permissions'), isTrue);
    expect(businessRules.any((rule) => rule['name'] == 'task_due_date_validation'), isTrue);
    
    // 验证测试策略
    final testingStrategy = yamlToMap(taskServiceYaml['testing_strategy']);
    expect(testingStrategy['unit_tests'], isNotNull, reason: 'TaskService should have unit tests');
    expect(testingStrategy['integration_tests'], isNotNull, reason: 'TaskService should have integration tests');
    expect(testingStrategy['mock_strategy'], isNotNull, reason: 'TaskService should have mock strategy');
  }

  // 验证 FocusFlowService
  static void validateFocusFlowService() {
    expect(focusFlowServiceYaml, isNotNull, reason: 'FocusFlowService YAML file should exist');
    
    final serviceDef = yamlToMap(focusFlowServiceYaml['service_definition']);
    expect(serviceDef['name'], equals('FocusFlowService'));
    expect(serviceDef['layer'], equals('business_logic'));
    expect(serviceDef['pattern'], equals('service'));
    expect(serviceDef['singleton'], equals(false));
    
    // 验证枚举
    final enums = yamlToList(focusFlowServiceYaml['enums']);
    expect(enums.length, equals(1), reason: 'FocusFlowService should have 1 enum');
    
    final focusOutcomeEnum = enums.first;
    expect(focusOutcomeEnum['name'], equals('FocusOutcome'));
    expect(focusOutcomeEnum['values'], contains('complete'));
    expect(focusOutcomeEnum['values'], contains('completeWithoutTimer'));
    expect(focusOutcomeEnum['values'], contains('addSubtask'));
    expect(focusOutcomeEnum['values'], contains('logMultiple'));
    expect(focusOutcomeEnum['values'], contains('markWasted'));
    
    // 验证公共方法
    final publicMethods = yamlToList(focusFlowServiceYaml['public_methods']);
    expect(publicMethods.length, equals(5), reason: 'FocusFlowService should have 5 public methods');
    
    final startFocusMethod = publicMethods.firstWhere((m) => m['name'] == 'startFocus');
    expect(startFocusMethod['return_type'], equals('Future<FocusSession>'));
    expect(startFocusMethod['parameters'].length, equals(3));
    
    final pauseFocusMethod = publicMethods.firstWhere((m) => m['name'] == 'pauseFocus');
    expect(pauseFocusMethod['return_type'], equals('Future<void>'));
    expect(pauseFocusMethod['parameters'].length, equals(1));
    
    final endFocusMethod = publicMethods.firstWhere((m) => m['name'] == 'endFocus');
    expect(endFocusMethod['return_type'], equals('Future<void>'));
    expect(endFocusMethod['parameters'].length, equals(3));
    
    // 验证私有方法
    final privateMethods = yamlToList(focusFlowServiceYaml['private_methods']);
    expect(privateMethods.length, equals(4), reason: 'FocusFlowService should have 4 private methods');
    
    final handleFocusCompleteMethod = privateMethods.firstWhere((m) => m['name'] == '_handleFocusComplete');
    expect(handleFocusCompleteMethod['return_type'], equals('Future<void>'));
    expect(handleFocusCompleteMethod['parameters'].length, equals(2));
    
    final handleAddSubtaskMethod = privateMethods.firstWhere((m) => m['name'] == '_handleAddSubtask');
    expect(handleAddSubtaskMethod['return_type'], equals('Future<void>'));
    expect(handleAddSubtaskMethod['parameters'].length, equals(2));
    
    final handleLogMultipleMethod = privateMethods.firstWhere((m) => m['name'] == '_handleLogMultiple');
    expect(handleLogMultipleMethod['return_type'], equals('Future<void>'));
    expect(handleLogMultipleMethod['parameters'].length, equals(2));
    
    final handleMarkWastedMethod = privateMethods.firstWhere((m) => m['name'] == '_handleMarkWasted');
    expect(handleMarkWastedMethod['return_type'], equals('Future<void>'));
    expect(handleMarkWastedMethod['parameters'].length, equals(2));
  }

  // 验证 MetricOrchestrator
  static void validateMetricOrchestrator() {
    expect(metricOrchestratorYaml, isNotNull, reason: 'MetricOrchestrator YAML file should exist');
    
    final serviceDef = yamlToMap(metricOrchestratorYaml['service_definition']);
    expect(serviceDef['name'], equals('MetricOrchestrator'));
    expect(serviceDef['layer'], equals('business_logic'));
    expect(serviceDef['pattern'], equals('orchestrator'));
    expect(serviceDef['singleton'], equals(false));
    
    // 验证枚举
    final enums = yamlToList(metricOrchestratorYaml['enums']);
    expect(enums.length, equals(1), reason: 'MetricOrchestrator should have 1 enum');
    
    final metricRecomputeReasonEnum = enums.first;
    expect(metricRecomputeReasonEnum['name'], equals('MetricRecomputeReason'));
    expect(metricRecomputeReasonEnum['values'], contains('task'));
    expect(metricRecomputeReasonEnum['values'], contains('session'));
    expect(metricRecomputeReasonEnum['values'], contains('seedImport'));
    
    // 验证公共方法
    final publicMethods = yamlToList(metricOrchestratorYaml['public_methods']);
    expect(publicMethods.length, equals(3), reason: 'MetricOrchestrator should have 3 public methods');
    
    final latestMethod = publicMethods.firstWhere((m) => m['name'] == 'latest');
    expect(latestMethod['return_type'], equals('Stream<MetricSnapshot?>'));
    expect(latestMethod['parameters'].length, equals(0));
    
    final requestRecomputeMethod = publicMethods.firstWhere((m) => m['name'] == 'requestRecompute');
    expect(requestRecomputeMethod['return_type'], equals('Future<MetricSnapshot>'));
    expect(requestRecomputeMethod['parameters'].length, equals(1));
    
    final invalidateMethod = publicMethods.firstWhere((m) => m['name'] == 'invalidate');
    expect(invalidateMethod['return_type'], equals('Future<void>'));
    expect(invalidateMethod['parameters'].length, equals(0));
    
    // 验证私有方法
    final privateMethods = yamlToList(metricOrchestratorYaml['private_methods']);
    expect(privateMethods.length, equals(2), reason: 'MetricOrchestrator should have 2 private methods');
    
    final calculateMetricsMethod = privateMethods.firstWhere((m) => m['name'] == '_calculateMetrics');
    expect(calculateMetricsMethod['return_type'], equals('Future<MetricSnapshot>'));
    expect(calculateMetricsMethod['parameters'].length, equals(2));
    
    final debounceRecomputeMethod = privateMethods.firstWhere((m) => m['name'] == '_debounceRecompute');
    expect(debounceRecomputeMethod['return_type'], equals('Future<MetricSnapshot>'));
    expect(debounceRecomputeMethod['parameters'].length, equals(1));
  }

  // 验证 PreferenceService
  static void validatePreferenceService() {
    expect(preferenceServiceYaml, isNotNull, reason: 'PreferenceService YAML file should exist');
    
    final serviceDef = yamlToMap(preferenceServiceYaml['service_definition']);
    expect(serviceDef['name'], equals('PreferenceService'));
    expect(serviceDef['layer'], equals('business_logic'));
    expect(serviceDef['pattern'], equals('service'));
    expect(serviceDef['singleton'], equals(false));
    
    // 验证公共方法
    final publicMethods = yamlToList(preferenceServiceYaml['public_methods']);
    expect(publicMethods.length, equals(5), reason: 'PreferenceService should have 5 public methods');
    
    final watchMethod = publicMethods.firstWhere((m) => m['name'] == 'watch');
    expect(watchMethod['return_type'], equals('Stream<Preference>'));
    expect(watchMethod['parameters'].length, equals(0));
    
    final updateMethod = publicMethods.firstWhere((m) => m['name'] == 'update');
    expect(updateMethod['return_type'], equals('Future<void>'));
    expect(updateMethod['parameters'].length, equals(1));
    
    final updateLocaleMethod = publicMethods.firstWhere((m) => m['name'] == 'updateLocale');
    expect(updateLocaleMethod['return_type'], equals('Future<void>'));
    expect(updateLocaleMethod['parameters'].length, equals(1));
    
    final updateThemeMethod = publicMethods.firstWhere((m) => m['name'] == 'updateTheme');
    expect(updateThemeMethod['return_type'], equals('Future<void>'));
    expect(updateThemeMethod['parameters'].length, equals(1));
    
    final updateFontScaleMethod = publicMethods.firstWhere((m) => m['name'] == 'updateFontScale');
    expect(updateFontScaleMethod['return_type'], equals('Future<void>'));
    expect(updateFontScaleMethod['parameters'].length, equals(1));
  }

  // 验证 TaskHierarchyService
  static void validateTaskHierarchyService() {
    expect(taskHierarchyServiceYaml, isNotNull, reason: 'TaskHierarchyService YAML file should exist');
    
    final serviceDef = yamlToMap(taskHierarchyServiceYaml['service_definition']);
    expect(serviceDef['name'], equals('TaskHierarchyService'));
    expect(serviceDef['layer'], equals('business_logic'));
    expect(serviceDef['pattern'], equals('service'));
    expect(serviceDef['singleton'], equals(false));
    
    // 验证公共方法
    final publicMethods = yamlToList(taskHierarchyServiceYaml['public_methods']);
    expect(publicMethods.length, equals(5), reason: 'TaskHierarchyService should have 5 public methods');
    
    final reorderWithinSectionMethod = publicMethods.firstWhere((m) => m['name'] == 'reorderWithinSection');
    expect(reorderWithinSectionMethod['return_type'], equals('Future<void>'));
    expect(reorderWithinSectionMethod['parameters'].length, equals(3));
    
    final moveToParentMethod = publicMethods.firstWhere((m) => m['name'] == 'moveToParent');
    expect(moveToParentMethod['return_type'], equals('Future<void>'));
    expect(moveToParentMethod['parameters'].length, equals(3));
    
    final moveToSectionMethod = publicMethods.firstWhere((m) => m['name'] == 'moveToSection');
    expect(moveToSectionMethod['return_type'], equals('Future<void>'));
    expect(moveToSectionMethod['parameters'].length, equals(3));
    
    final createSubtaskMethod = publicMethods.firstWhere((m) => m['name'] == 'createSubtask');
    expect(createSubtaskMethod['return_type'], equals('Future<Task>'));
    expect(createSubtaskMethod['parameters'].length, equals(3));
    
    final getTaskHierarchyMethod = publicMethods.firstWhere((m) => m['name'] == 'getTaskHierarchy');
    expect(getTaskHierarchyMethod['return_type'], equals('Future<TaskTreeNode>'));
    expect(getTaskHierarchyMethod['parameters'].length, equals(1));
    
    // 验证私有方法
    final privateMethods = yamlToList(taskHierarchyServiceYaml['private_methods']);
    expect(privateMethods.length, equals(3), reason: 'TaskHierarchyService should have 3 private methods');
    
    final validateTaskMoveMethod = privateMethods.firstWhere((m) => m['name'] == '_validateTaskMove');
    expect(validateTaskMoveMethod['return_type'], equals('void'));
    expect(validateTaskMoveMethod['parameters'].length, equals(2));
    
    final validateParentTaskMethod = privateMethods.firstWhere((m) => m['name'] == '_validateParentTask');
    expect(validateParentTaskMethod['return_type'], equals('void'));
    expect(validateParentTaskMethod['parameters'].length, equals(1));
    
    final checkCircularDependencyMethod = privateMethods.firstWhere((m) => m['name'] == '_checkCircularDependency');
    expect(checkCircularDependencyMethod['return_type'], equals('bool'));
    expect(checkCircularDependencyMethod['parameters'].length, equals(2));
  }

  // 验证 TaskTemplateService
  static void validateTaskTemplateService() {
    expect(taskTemplateServiceYaml, isNotNull, reason: 'TaskTemplateService YAML file should exist');
    
    final serviceDef = yamlToMap(taskTemplateServiceYaml['service_definition']);
    expect(serviceDef['name'], equals('TaskTemplateService'));
    expect(serviceDef['layer'], equals('business_logic'));
    expect(serviceDef['pattern'], equals('service'));
    expect(serviceDef['singleton'], equals(false));
    
    // 验证公共方法
    final publicMethods = yamlToList(taskTemplateServiceYaml['public_methods']);
    expect(publicMethods.length, equals(8), reason: 'TaskTemplateService should have 8 public methods');
    
    final createTemplateMethod = publicMethods.firstWhere((m) => m['name'] == 'createTemplate');
    expect(createTemplateMethod['return_type'], equals('Future<TaskTemplate>'));
    expect(createTemplateMethod['parameters'].length, equals(1));
    
    final updateTemplateMethod = publicMethods.firstWhere((m) => m['name'] == 'updateTemplate');
    expect(updateTemplateMethod['return_type'], equals('Future<void>'));
    expect(updateTemplateMethod['parameters'].length, equals(2));
    
    final deleteTemplateMethod = publicMethods.firstWhere((m) => m['name'] == 'deleteTemplate');
    expect(deleteTemplateMethod['return_type'], equals('Future<void>'));
    expect(deleteTemplateMethod['parameters'].length, equals(1));
    
    final listRecentMethod = publicMethods.firstWhere((m) => m['name'] == 'listRecent');
    expect(listRecentMethod['return_type'], equals('Future<List<TaskTemplate>>'));
    expect(listRecentMethod['parameters'].length, equals(1));
    
    final searchMethod = publicMethods.firstWhere((m) => m['name'] == 'search');
    expect(searchMethod['return_type'], equals('Future<List<TaskTemplate>>'));
    expect(searchMethod['parameters'].length, equals(2));
    
    final useTemplateMethod = publicMethods.firstWhere((m) => m['name'] == 'useTemplate');
    expect(useTemplateMethod['return_type'], equals('Future<Task>'));
    expect(useTemplateMethod['parameters'].length, equals(2));
    
    final findByIdMethod = publicMethods.firstWhere((m) => m['name'] == 'findById');
    expect(findByIdMethod['return_type'], equals('Future<TaskTemplate?>'));
    expect(findByIdMethod['parameters'].length, equals(1));
    
    final findBySlugMethod = publicMethods.firstWhere((m) => m['name'] == 'findBySlug');
    expect(findBySlugMethod['return_type'], equals('Future<TaskTemplate?>'));
    expect(findBySlugMethod['parameters'].length, equals(1));
    
    // 验证私有方法
    final privateMethods = yamlToList(taskTemplateServiceYaml['private_methods']);
    expect(privateMethods.length, equals(3), reason: 'TaskTemplateService should have 3 private methods');
    
    final updateTemplateInternalMethod = privateMethods.firstWhere((m) => m['name'] == '_updateTemplateInternal');
    expect(updateTemplateInternalMethod['return_type'], equals('Future<void>'));
    expect(updateTemplateInternalMethod['parameters'].length, equals(2));
    
    final adjustTemplateLockMethod = privateMethods.firstWhere((m) => m['name'] == '_adjustTemplateLock');
    expect(adjustTemplateLockMethod['return_type'], equals('Future<void>'));
    expect(adjustTemplateLockMethod['parameters'].length, equals(2));
    
    final createTaskFromTemplateMethod = privateMethods.firstWhere((m) => m['name'] == '_createTaskFromTemplate');
    expect(createTaskFromTemplateMethod['return_type'], equals('Future<Task>'));
    expect(createTaskFromTemplateMethod['parameters'].length, equals(2));
  }

  // 验证 SeedImportService
  static void validateSeedImportService() {
    expect(seedImportServiceYaml, isNotNull, reason: 'SeedImportService YAML file should exist');
    
    final serviceDef = yamlToMap(seedImportServiceYaml['service_definition']);
    expect(serviceDef['name'], equals('SeedImportService'));
    expect(serviceDef['layer'], equals('business_logic'));
    expect(serviceDef['pattern'], equals('service'));
    expect(serviceDef['singleton'], equals(false));
    
    // 验证公共方法
    final publicMethods = yamlToList(seedImportServiceYaml['public_methods']);
    expect(publicMethods.length, equals(3), reason: 'SeedImportService should have 3 public methods');
    
    final importIfNeededMethod = publicMethods.firstWhere((m) => m['name'] == 'importIfNeeded');
    expect(importIfNeededMethod['return_type'], equals('Future<void>'));
    expect(importIfNeededMethod['parameters'].length, equals(1));
    
    final loadSeedPayloadMethod = publicMethods.firstWhere((m) => m['name'] == 'loadSeedPayload');
    expect(loadSeedPayloadMethod['return_type'], equals('Future<SeedPayload>'));
    expect(loadSeedPayloadMethod['parameters'].length, equals(1));
    
    final checkImportStatusMethod = publicMethods.firstWhere((m) => m['name'] == 'checkImportStatus');
    expect(checkImportStatusMethod['return_type'], equals('Future<bool>'));
    expect(checkImportStatusMethod['parameters'].length, equals(1));
    
    // 验证私有方法
    final privateMethods = yamlToList(seedImportServiceYaml['private_methods']);
    expect(privateMethods.length, equals(5), reason: 'SeedImportService should have 5 private methods');
    
    final applyTagsMethod = privateMethods.firstWhere((m) => m['name'] == '_applyTags');
    expect(applyTagsMethod['return_type'], equals('Future<void>'));
    expect(applyTagsMethod['parameters'].length, equals(1));
    
    final applyTasksMethod = privateMethods.firstWhere((m) => m['name'] == '_applyTasks');
    expect(applyTasksMethod['return_type'], equals('Future<Map<String, int>>'));
    expect(applyTasksMethod['parameters'].length, equals(1));
    
    final applyInboxItemsMethod = privateMethods.firstWhere((m) => m['name'] == '_applyInboxItems');
    expect(applyInboxItemsMethod['return_type'], equals('Future<void>'));
    expect(applyInboxItemsMethod['parameters'].length, equals(2));
    
    final applyTemplatesMethod = privateMethods.firstWhere((m) => m['name'] == '_applyTemplates');
    expect(applyTemplatesMethod['return_type'], equals('Future<void>'));
    expect(applyTemplatesMethod['parameters'].length, equals(2));
    
    final validateSeedDataMethod = privateMethods.firstWhere((m) => m['name'] == '_validateSeedData');
    expect(validateSeedDataMethod['return_type'], equals('void'));
    expect(validateSeedDataMethod['parameters'].length, equals(1));
  }

  // 验证所有服务的一致性
  static void validateAllServicesConsistency() {
    // 验证所有服务都有正确的元数据
    final allYamls = [taskServiceYaml, focusFlowServiceYaml, metricOrchestratorYaml, preferenceServiceYaml, taskHierarchyServiceYaml, taskTemplateServiceYaml, seedImportServiceYaml];
    
    for (final yaml in allYamls) {
      expect(yaml['meta'], isNotNull, reason: 'All services should have meta section');
      expect(yaml['meta']['name'], isNotNull, reason: 'All services should have name');
      expect(yaml['meta']['type'], equals('service'), reason: 'All services should have type service');
      expect(yaml['meta']['file_path'], isNotNull, reason: 'All services should have file_path');
      expect(yaml['meta']['description'], isNotNull, reason: 'All services should have description');
      
      expect(yaml['service_definition'], isNotNull, reason: 'All services should have service_definition');
      expect(yaml['service_definition']['name'], isNotNull, reason: 'All services should have service name');
      expect(yaml['service_definition']['layer'], equals('business_logic'), reason: 'All services should have layer business_logic');
      expect(yaml['service_definition']['pattern'], isNotNull, reason: 'All services should have pattern');
      expect(yaml['service_definition']['singleton'], isNotNull, reason: 'All services should have singleton');
      
      expect(yaml['constructor'], isNotNull, reason: 'All services should have constructor');
      expect(yaml['constructor']['parameters'], isNotNull, reason: 'All services should have constructor parameters');
      expect(yaml['constructor']['dependencies'], isNotNull, reason: 'All services should have constructor dependencies');
      
      expect(yaml['public_methods'], isNotNull, reason: 'All services should have public_methods');
      expect(yaml['public_methods'], isA<List>(), reason: 'All services should have public_methods as list');
      expect((yaml['public_methods'] as List).isNotEmpty, isTrue, reason: 'All services should have non-empty public_methods');
      
      if (yaml['private_methods'] != null) {
        expect(yaml['private_methods'], isA<List>(), reason: 'All services should have private_methods as list');
      }
      
      expect(yaml['fields'], isNotNull, reason: 'All services should have fields');
      expect(yaml['fields'], isA<List>(), reason: 'All services should have fields as list');
      expect((yaml['fields'] as List).isNotEmpty, isTrue, reason: 'All services should have non-empty fields');
      
      expect(yaml['dependencies'], isNotNull, reason: 'All services should have dependencies');
      expect(yaml['dependencies'], isA<List>(), reason: 'All services should have dependencies as list');
      
      expect(yaml['responsibilities'], isNotNull, reason: 'All services should have responsibilities');
      expect(yaml['responsibilities'], isA<List>(), reason: 'All services should have responsibilities as list');
      expect((yaml['responsibilities'] as List).isNotEmpty, isTrue, reason: 'All services should have non-empty responsibilities');
      
      expect(yaml['business_operations'], isNotNull, reason: 'All services should have business_operations');
      expect(yaml['business_operations'], isA<Map>(), reason: 'All services should have business_operations as map');
      
      expect(yaml['testing_strategy'], isNotNull, reason: 'All services should have testing_strategy');
      expect(yaml['testing_strategy'], isA<Map>(), reason: 'All services should have testing_strategy as map');
    }
  }
}

void main() {
  group('Services YAML Tests', () {
    setUpAll(() async {
      await ServicesYAMLTest.loadYAMLFiles();
    });

    test('TaskService should match YAML definition', () {
      ServicesYAMLTest.validateTaskService();
    });

    test('FocusFlowService should match YAML definition', () {
      ServicesYAMLTest.validateFocusFlowService();
    });

    test('MetricOrchestrator should match YAML definition', () {
      ServicesYAMLTest.validateMetricOrchestrator();
    });

    test('PreferenceService should match YAML definition', () {
      ServicesYAMLTest.validatePreferenceService();
    });

    test('TaskHierarchyService should match YAML definition', () {
      ServicesYAMLTest.validateTaskHierarchyService();
    });

    test('TaskTemplateService should match YAML definition', () {
      ServicesYAMLTest.validateTaskTemplateService();
    });

    test('SeedImportService should match YAML definition', () {
      ServicesYAMLTest.validateSeedImportService();
    });

    test('All services should have consistent structure', () {
      ServicesYAMLTest.validateAllServicesConsistency();
    });
  });
}
