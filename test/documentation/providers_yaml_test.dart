// ============================================================================
// 📋 YAML 架构文档验证测试 - Providers
// ============================================================================
//
// ⚠️ 重要说明：本测试文件用于验证代码实现与 YAML 架构文档的一致性
//
// 🎯 测试目的：
// 1. 确保 documents/architecture/providers/*.yaml 文档准确反映代码实现
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

class ProvidersYAMLTest {
  static late Map<String, dynamic> appProvidersYaml;
  static late Map<String, dynamic> repositoryProvidersYaml;
  static late Map<String, dynamic> serviceProvidersYaml;

  static Future<void> loadYAMLFiles() async {
    appProvidersYaml = yamlToMap(loadYaml(await File('documents/architecture/providers/app_providers.yaml').readAsString()));
    repositoryProvidersYaml = yamlToMap(loadYaml(await File('documents/architecture/providers/repository_providers.yaml').readAsString()));
    serviceProvidersYaml = yamlToMap(loadYaml(await File('documents/architecture/providers/service_providers.yaml').readAsString()));
  }

  // 验证 AppProviders
  static void validateAppProviders() {
    // 验证 YAML 文件存在
    expect(appProvidersYaml, isNotNull, reason: 'AppProviders YAML file should exist');
    
    // 验证元数据
    expect(appProvidersYaml['meta']['name'], equals('AppProviders'));
    expect(appProvidersYaml['meta']['type'], equals('provider'));
    expect(appProvidersYaml['meta']['file_path'], equals('lib/core/providers/app_providers.dart'));
    
    // 验证 Provider 定义
    final providerDef = yamlToMap(appProvidersYaml['provider_definition']);
    expect(providerDef['name'], equals('AppProviders'));
    expect(providerDef['layer'], equals('dependency_injection'));
    expect(providerDef['pattern'], equals('provider'));
    expect(providerDef['scope'], equals('global'));
    expect(providerDef['auto_dispose'], equals(false));
    
    // 验证 Provider 类型
    final providerTypes = yamlToList(appProvidersYaml['provider_types']);
    expect(providerTypes.length, equals(3), reason: 'AppProviders should have 3 provider types');
    expect(providerTypes.any((type) => type['name'] == 'Provider'), isTrue);
    expect(providerTypes.any((type) => type['name'] == 'StreamProvider'), isTrue);
    expect(providerTypes.any((type) => type['name'] == 'FutureProvider'), isTrue);
    
    // 验证 Providers
    final providers = yamlToList(appProvidersYaml['providers']);
    expect(providers.length, equals(14), reason: 'AppProviders should have 14 providers');
    
    // 验证关键 Provider
    final appLocaleProvider = providers.firstWhere((p) => p['name'] == 'appLocaleProvider');
    expect(appLocaleProvider['type'], equals('StreamProvider'));
    expect(appLocaleProvider['return_type'], equals('Locale'));
    expect(appLocaleProvider['dependencies'].length, equals(1));
    
    final themeProvider = providers.firstWhere((p) => p['name'] == 'themeProvider');
    expect(themeProvider['type'], equals('StreamProvider'));
    expect(themeProvider['return_type'], equals('ThemeMode'));
    expect(themeProvider['dependencies'].length, equals(1));
    
    final fontScaleProvider = providers.firstWhere((p) => p['name'] == 'fontScaleProvider');
    expect(fontScaleProvider['type'], equals('StreamProvider'));
    expect(fontScaleProvider['return_type'], equals('double'));
    expect(fontScaleProvider['dependencies'].length, equals(1));
    
    final seedInitializerProvider = providers.firstWhere((p) => p['name'] == 'seedInitializerProvider');
    expect(seedInitializerProvider['type'], equals('FutureProvider'));
    expect(seedInitializerProvider['return_type'], equals('void'));
    expect(seedInitializerProvider['dependencies'].length, equals(2));
    expect(seedInitializerProvider['keep_alive'], equals(true));
    
    final taskListProvider = providers.firstWhere((p) => p['name'] == 'taskListProvider');
    expect(taskListProvider['type'], equals('StreamProvider'));
    expect(taskListProvider['return_type'], equals('List<Task>'));
    expect(taskListProvider['dependencies'].length, equals(1));
    
    final inboxProvider = providers.firstWhere((p) => p['name'] == 'inboxProvider');
    expect(inboxProvider['type'], equals('StreamProvider'));
    expect(inboxProvider['return_type'], equals('List<Task>'));
    expect(inboxProvider['dependencies'].length, equals(1));
    
    final completedProvider = providers.firstWhere((p) => p['name'] == 'completedProvider');
    expect(completedProvider['type'], equals('StreamProvider'));
    expect(completedProvider['return_type'], equals('List<Task>'));
    expect(completedProvider['dependencies'].length, equals(1));
    
    final archivedProvider = providers.firstWhere((p) => p['name'] == 'archivedProvider');
    expect(archivedProvider['type'], equals('StreamProvider'));
    expect(archivedProvider['return_type'], equals('List<Task>'));
    expect(archivedProvider['dependencies'].length, equals(1));
    
    final trashProvider = providers.firstWhere((p) => p['name'] == 'trashProvider');
    expect(trashProvider['type'], equals('StreamProvider'));
    expect(trashProvider['return_type'], equals('List<Task>'));
    expect(trashProvider['dependencies'].length, equals(1));
    
    final activeFocusSessionProvider = providers.firstWhere((p) => p['name'] == 'activeFocusSessionProvider');
    expect(activeFocusSessionProvider['type'], equals('StreamProvider'));
    expect(activeFocusSessionProvider['return_type'], equals('FocusSession?'));
    expect(activeFocusSessionProvider['dependencies'].length, equals(1));
    
    final metricSnapshotProvider = providers.firstWhere((p) => p['name'] == 'metricSnapshotProvider');
    expect(metricSnapshotProvider['type'], equals('StreamProvider'));
    expect(metricSnapshotProvider['return_type'], equals('MetricSnapshot?'));
    expect(metricSnapshotProvider['dependencies'].length, equals(1));
    
    final taskTemplateListProvider = providers.firstWhere((p) => p['name'] == 'taskTemplateListProvider');
    expect(taskTemplateListProvider['type'], equals('StreamProvider'));
    expect(taskTemplateListProvider['return_type'], equals('List<TaskTemplate>'));
    expect(taskTemplateListProvider['dependencies'].length, equals(1));
    
    final tagListProvider = providers.firstWhere((p) => p['name'] == 'tagListProvider');
    expect(tagListProvider['type'], equals('StreamProvider'));
    expect(tagListProvider['return_type'], equals('List<Tag>'));
    expect(tagListProvider['dependencies'].length, equals(1));
    
    final monetizationStateProvider = providers.firstWhere((p) => p['name'] == 'monetizationStateProvider');
    expect(monetizationStateProvider['type'], equals('StreamProvider'));
    expect(monetizationStateProvider['return_type'], equals('MonetizationState'));
    expect(monetizationStateProvider['dependencies'].length, equals(1));
    
    // 验证依赖
    final dependencies = yamlToList(appProvidersYaml['dependencies']);
    expect(dependencies.length, equals(14), reason: 'AppProviders should have 14 dependencies');
    expect(dependencies.any((d) => d['name'] == 'PreferenceService'), isTrue);
    expect(dependencies.any((d) => d['name'] == 'TaskService'), isTrue);
    expect(dependencies.any((d) => d['name'] == 'FocusFlowService'), isTrue);
    expect(dependencies.any((d) => d['name'] == 'MetricOrchestrator'), isTrue);
    
    // 验证职责
    final responsibilities = yamlToList(appProvidersYaml['responsibilities']);
    expect(responsibilities.length, equals(10), reason: 'AppProviders should have 10 responsibilities');
    expect(responsibilities, contains('全局状态管理'));
    expect(responsibilities, contains('依赖注入管理'));
    expect(responsibilities, contains('应用配置管理'));
    
    // 验证 Provider 分类
    final providerCategories = yamlToMap(appProvidersYaml['provider_categories']);
    expect(providerCategories['repository_providers'], isNotNull);
    expect(providerCategories['service_providers'], isNotNull);
    expect(providerCategories['stream_providers'], isNotNull);
    expect(providerCategories['future_providers'], isNotNull);
    expect(providerCategories['app_providers'], isNotNull);
  }

  // 验证 RepositoryProviders
  static void validateRepositoryProviders() {
    expect(repositoryProvidersYaml, isNotNull, reason: 'RepositoryProviders YAML file should exist');
    
    final providerDef = yamlToMap(repositoryProvidersYaml['provider_definition']);
    expect(providerDef['name'], equals('RepositoryProviders'));
    expect(providerDef['layer'], equals('dependency_injection'));
    expect(providerDef['pattern'], equals('provider'));
    expect(providerDef['scope'], equals('global'));
    expect(providerDef['auto_dispose'], equals(false));
    
    // 验证 Provider 类型
    final providerTypes = yamlToList(repositoryProvidersYaml['provider_types']);
    expect(providerTypes.length, equals(1), reason: 'RepositoryProviders should have 1 provider type');
    expect(providerTypes.any((type) => type['name'] == 'Provider'), isTrue);
    
    // 验证 Providers
    final providers = yamlToList(repositoryProvidersYaml['providers']);
    expect(providers.length, equals(8), reason: 'RepositoryProviders should have 8 providers');
    
    // 验证关键 Provider
    final isarProvider = providers.firstWhere((p) => p['name'] == 'isarProvider');
    expect(isarProvider['type'], equals('Provider'));
    expect(isarProvider['return_type'], equals('Isar'));
    expect(isarProvider['dependencies'].length, equals(0));
    
    final taskRepositoryProvider = providers.firstWhere((p) => p['name'] == 'taskRepositoryProvider');
    expect(taskRepositoryProvider['type'], equals('Provider'));
    expect(taskRepositoryProvider['return_type'], equals('TaskRepository'));
    expect(taskRepositoryProvider['dependencies'].length, equals(1));
    
    final focusSessionRepositoryProvider = providers.firstWhere((p) => p['name'] == 'focusSessionRepositoryProvider');
    expect(focusSessionRepositoryProvider['type'], equals('Provider'));
    expect(focusSessionRepositoryProvider['return_type'], equals('FocusSessionRepository'));
    expect(focusSessionRepositoryProvider['dependencies'].length, equals(1));
    
    final tagRepositoryProvider = providers.firstWhere((p) => p['name'] == 'tagRepositoryProvider');
    expect(tagRepositoryProvider['type'], equals('Provider'));
    expect(tagRepositoryProvider['return_type'], equals('TagRepository'));
    expect(tagRepositoryProvider['dependencies'].length, equals(1));
    
    final preferenceRepositoryProvider = providers.firstWhere((p) => p['name'] == 'preferenceRepositoryProvider');
    expect(preferenceRepositoryProvider['type'], equals('Provider'));
    expect(preferenceRepositoryProvider['return_type'], equals('PreferenceRepository'));
    expect(preferenceRepositoryProvider['dependencies'].length, equals(1));
    
    final metricRepositoryProvider = providers.firstWhere((p) => p['name'] == 'metricRepositoryProvider');
    expect(metricRepositoryProvider['type'], equals('Provider'));
    expect(metricRepositoryProvider['return_type'], equals('MetricRepository'));
    expect(metricRepositoryProvider['dependencies'].length, equals(0));
    
    final taskTemplateRepositoryProvider = providers.firstWhere((p) => p['name'] == 'taskTemplateRepositoryProvider');
    expect(taskTemplateRepositoryProvider['type'], equals('Provider'));
    expect(taskTemplateRepositoryProvider['return_type'], equals('TaskTemplateRepository'));
    expect(taskTemplateRepositoryProvider['dependencies'].length, equals(1));
    
    final seedRepositoryProvider = providers.firstWhere((p) => p['name'] == 'seedRepositoryProvider');
    expect(seedRepositoryProvider['type'], equals('Provider'));
    expect(seedRepositoryProvider['return_type'], equals('SeedRepository'));
    expect(seedRepositoryProvider['dependencies'].length, equals(1));
    
    // 验证依赖
    final dependencies = yamlToList(repositoryProvidersYaml['dependencies']);
    expect(dependencies.length, equals(8), reason: 'RepositoryProviders should have 8 dependencies');
    expect(dependencies.any((d) => d['name'] == 'Isar'), isTrue);
    expect(dependencies.any((d) => d['name'] == 'TaskRepository'), isTrue);
    expect(dependencies.any((d) => d['name'] == 'FocusSessionRepository'), isTrue);
    
    // 验证职责
    final responsibilities = yamlToList(repositoryProvidersYaml['responsibilities']);
    expect(responsibilities.length, equals(6), reason: 'RepositoryProviders should have 6 responsibilities');
    expect(responsibilities, contains('数据访问层依赖注入'));
    expect(responsibilities, contains('数据库实例管理'));
    expect(responsibilities, contains('仓库实例管理'));
    
    // 验证 Provider 分类
    final providerCategories = yamlToMap(repositoryProvidersYaml['provider_categories']);
    expect(providerCategories['repository_providers'], isNotNull);
    expect(providerCategories['database_providers'], isNotNull);
  }

  // 验证 ServiceProviders
  static void validateServiceProviders() {
    expect(serviceProvidersYaml, isNotNull, reason: 'ServiceProviders YAML file should exist');
    
    final providerDef = yamlToMap(serviceProvidersYaml['provider_definition']);
    expect(providerDef['name'], equals('ServiceProviders'));
    expect(providerDef['layer'], equals('dependency_injection'));
    expect(providerDef['pattern'], equals('provider'));
    expect(providerDef['scope'], equals('global'));
    expect(providerDef['auto_dispose'], equals(false));
    
    // 验证 Provider 类型
    final providerTypes = yamlToList(serviceProvidersYaml['provider_types']);
    expect(providerTypes.length, equals(1), reason: 'ServiceProviders should have 1 provider type');
    expect(providerTypes.any((type) => type['name'] == 'Provider'), isTrue);
    
    // 验证 Providers
    final providers = yamlToList(serviceProvidersYaml['providers']);
    expect(providers.length, equals(10), reason: 'ServiceProviders should have 10 providers');
    
    // 验证关键 Provider
    final metricOrchestratorProvider = providers.firstWhere((p) => p['name'] == 'metricOrchestratorProvider');
    expect(metricOrchestratorProvider['type'], equals('Provider'));
    expect(metricOrchestratorProvider['return_type'], equals('MetricOrchestrator'));
    expect(metricOrchestratorProvider['dependencies'].length, equals(3));
    
    final configOverridesProvider = providers.firstWhere((p) => p['name'] == 'configOverridesProvider');
    expect(configOverridesProvider['type'], equals('Provider'));
    expect(configOverridesProvider['return_type'], equals('AppConfig?'));
    expect(configOverridesProvider['dependencies'].length, equals(0));
    
    final appConfigProvider = providers.firstWhere((p) => p['name'] == 'appConfigProvider');
    expect(appConfigProvider['type'], equals('Provider'));
    expect(appConfigProvider['return_type'], equals('AppConfig'));
    expect(appConfigProvider['dependencies'].length, equals(1));
    
    final taskServiceProvider = providers.firstWhere((p) => p['name'] == 'taskServiceProvider');
    expect(taskServiceProvider['type'], equals('Provider'));
    expect(taskServiceProvider['return_type'], equals('TaskService'));
    expect(taskServiceProvider['dependencies'].length, equals(3));
    
    final taskHierarchyServiceProvider = providers.firstWhere((p) => p['name'] == 'taskHierarchyServiceProvider');
    expect(taskHierarchyServiceProvider['type'], equals('Provider'));
    expect(taskHierarchyServiceProvider['return_type'], equals('TaskHierarchyService'));
    expect(taskHierarchyServiceProvider['dependencies'].length, equals(2));
    
    final focusFlowServiceProvider = providers.firstWhere((p) => p['name'] == 'focusFlowServiceProvider');
    expect(focusFlowServiceProvider['type'], equals('Provider'));
    expect(focusFlowServiceProvider['return_type'], equals('FocusFlowService'));
    expect(focusFlowServiceProvider['dependencies'].length, equals(4));
    
    final preferenceServiceProvider = providers.firstWhere((p) => p['name'] == 'preferenceServiceProvider');
    expect(preferenceServiceProvider['type'], equals('Provider'));
    expect(preferenceServiceProvider['return_type'], equals('PreferenceService'));
    expect(preferenceServiceProvider['dependencies'].length, equals(1));
    
    final taskTemplateServiceProvider = providers.firstWhere((p) => p['name'] == 'taskTemplateServiceProvider');
    expect(taskTemplateServiceProvider['type'], equals('Provider'));
    expect(taskTemplateServiceProvider['return_type'], equals('TaskTemplateService'));
    expect(taskTemplateServiceProvider['dependencies'].length, equals(3));
    
    final seedImportServiceProvider = providers.firstWhere((p) => p['name'] == 'seedImportServiceProvider');
    expect(seedImportServiceProvider['type'], equals('Provider'));
    expect(seedImportServiceProvider['return_type'], equals('SeedImportService'));
    expect(seedImportServiceProvider['dependencies'].length, equals(5));
    
    final monetizationServiceProvider = providers.firstWhere((p) => p['name'] == 'monetizationServiceProvider');
    expect(monetizationServiceProvider['type'], equals('Provider'));
    expect(monetizationServiceProvider['return_type'], equals('MonetizationService'));
    expect(monetizationServiceProvider['dependencies'].length, equals(1));
    
    // 验证依赖
    final dependencies = yamlToList(serviceProvidersYaml['dependencies']);
    expect(dependencies.length, equals(16), reason: 'ServiceProviders should have 16 dependencies');
    expect(dependencies.any((d) => d['name'] == 'MetricOrchestrator'), isTrue);
    expect(dependencies.any((d) => d['name'] == 'TaskService'), isTrue);
    expect(dependencies.any((d) => d['name'] == 'FocusFlowService'), isTrue);
    
    // 验证职责
    final responsibilities = yamlToList(serviceProvidersYaml['responsibilities']);
    expect(responsibilities.length, equals(6), reason: 'ServiceProviders should have 6 responsibilities');
    expect(responsibilities, contains('业务逻辑层依赖注入'));
    expect(responsibilities, contains('服务实例管理'));
    expect(responsibilities, contains('服务协调'));
    
    // 验证 Provider 分类
    final providerCategories = yamlToMap(serviceProvidersYaml['provider_categories']);
    expect(providerCategories['service_providers'], isNotNull);
    expect(providerCategories['config_providers'], isNotNull);
  }

  // 验证所有 Provider 的一致性
  static void validateAllProvidersConsistency() {
    // 验证所有 Provider 都有正确的元数据
    final allYamls = [appProvidersYaml, repositoryProvidersYaml, serviceProvidersYaml];
    
    for (final yaml in allYamls) {
      expect(yaml['meta'], isNotNull, reason: 'All providers should have meta section');
      expect(yaml['meta']['name'], isNotNull, reason: 'All providers should have name');
      expect(yaml['meta']['type'], equals('provider'), reason: 'All providers should have type provider');
      expect(yaml['meta']['file_path'], isNotNull, reason: 'All providers should have file_path');
      expect(yaml['meta']['description'], isNotNull, reason: 'All providers should have description');
      
      expect(yaml['provider_definition'], isNotNull, reason: 'All providers should have provider_definition');
      expect(yaml['provider_definition']['name'], isNotNull, reason: 'All providers should have provider name');
      expect(yaml['provider_definition']['layer'], equals('dependency_injection'), reason: 'All providers should have layer dependency_injection');
      expect(yaml['provider_definition']['pattern'], isNotNull, reason: 'All providers should have pattern');
      expect(yaml['provider_definition']['scope'], isNotNull, reason: 'All providers should have scope');
      expect(yaml['provider_definition']['auto_dispose'], isNotNull, reason: 'All providers should have auto_dispose');
      
      expect(yaml['provider_types'], isNotNull, reason: 'All providers should have provider_types');
      expect(yaml['provider_types'], isA<List>(), reason: 'All providers should have provider_types as list');
      expect((yaml['provider_types'] as List).isNotEmpty, isTrue, reason: 'All providers should have non-empty provider_types');
      
      expect(yaml['providers'], isNotNull, reason: 'All providers should have providers');
      expect(yaml['providers'], isA<List>(), reason: 'All providers should have providers as list');
      expect((yaml['providers'] as List).isNotEmpty, isTrue, reason: 'All providers should have non-empty providers');
      
      expect(yaml['dependencies'], isNotNull, reason: 'All providers should have dependencies');
      expect(yaml['dependencies'], isA<List>(), reason: 'All providers should have dependencies as list');
      
      expect(yaml['responsibilities'], isNotNull, reason: 'All providers should have responsibilities');
      expect(yaml['responsibilities'], isA<List>(), reason: 'All providers should have responsibilities as list');
      expect((yaml['responsibilities'] as List).isNotEmpty, isTrue, reason: 'All providers should have non-empty responsibilities');
      
      expect(yaml['provider_categories'], isNotNull, reason: 'All providers should have provider_categories');
      expect(yaml['provider_categories'], isA<Map>(), reason: 'All providers should have provider_categories as map');
      
      expect(yaml['lifecycle_management'], isNotNull, reason: 'All providers should have lifecycle_management');
      expect(yaml['lifecycle_management'], isA<List>(), reason: 'All providers should have lifecycle_management as list');
      
      expect(yaml['testing_strategy'], isNotNull, reason: 'All providers should have testing_strategy');
      expect(yaml['testing_strategy'], isA<Map>(), reason: 'All providers should have testing_strategy as map');
    }
  }
}

void main() {
  group('Providers YAML Tests', () {
    setUpAll(() async {
      await ProvidersYAMLTest.loadYAMLFiles();
    });

    test('AppProviders should match YAML definition', () {
      ProvidersYAMLTest.validateAppProviders();
    });

    test('RepositoryProviders should match YAML definition', () {
      ProvidersYAMLTest.validateRepositoryProviders();
    });

    test('ServiceProviders should match YAML definition', () {
      ProvidersYAMLTest.validateServiceProviders();
    });

    test('All providers should have consistent structure', () {
      ProvidersYAMLTest.validateAllProvidersConsistency();
    });
  });
}
