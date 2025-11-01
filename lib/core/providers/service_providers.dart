import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/focus_flow_service.dart';
import '../services/metric_orchestrator.dart';
import '../services/preference_service.dart';
import '../services/seed_import_service.dart';
import '../services/task_hierarchy_service.dart';
import '../services/task_service.dart';
import '../services/sort_index_service.dart';
import '../services/task_template_service.dart';
import '../monetization/monetization_service.dart';
import 'repository_providers.dart';

final metricOrchestratorProvider = Provider<MetricOrchestrator>((ref) {
  return MetricOrchestrator(
    metricRepository: ref.watch(metricRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    focusRepository: ref.watch(focusSessionRepositoryProvider),
  );
});

final configOverridesProvider = Provider<AppConfig?>((_) => null);

final appConfigProvider = Provider<AppConfig>((ref) {
  final overrides = ref.watch(configOverridesProvider);
  if (overrides != null) {
    return overrides;
  }
  return AppConfig.fromEnvironment();
});

final sortIndexServiceProvider = Provider<SortIndexService>((ref) {
  return SortIndexService(
    taskRepository: ref.watch(taskRepositoryProvider),
  );
});

final taskServiceProvider = Provider<TaskService>((ref) {
  return TaskService(
    taskRepository: ref.watch(taskRepositoryProvider),
    tagRepository: ref.watch(tagRepositoryProvider),
    metricOrchestrator: ref.watch(metricOrchestratorProvider),
    sortIndexService: ref.watch(sortIndexServiceProvider),
  );
});

final taskHierarchyServiceProvider = Provider<TaskHierarchyService>((ref) {
  return TaskHierarchyService(
    taskRepository: ref.watch(taskRepositoryProvider),
    metricOrchestrator: ref.watch(metricOrchestratorProvider),
  );
});

final focusFlowServiceProvider = Provider<FocusFlowService>((ref) {
  return FocusFlowService(
    focusRepository: ref.watch(focusSessionRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    taskService: ref.watch(taskServiceProvider),
    metricOrchestrator: ref.watch(metricOrchestratorProvider),
  );
});

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  final service = MonetizationService();
  ref.onDispose(service.dispose);
  return service;
});

final taskTemplateServiceProvider = Provider<TaskTemplateService>((ref) {
  return TaskTemplateService(
    templateRepository: ref.watch(taskTemplateRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    taskService: ref.watch(taskServiceProvider),
  );
});

final preferenceServiceProvider = Provider<PreferenceService>((ref) {
  return PreferenceService(repository: ref.watch(preferenceRepositoryProvider));
});

final seedImportServiceProvider = Provider<SeedImportService>((ref) {
  return SeedImportService(
    seedRepository: ref.watch(seedRepositoryProvider),
    tagRepository: ref.watch(tagRepositoryProvider),
    taskRepository: ref.watch(taskRepositoryProvider),
    templateRepository: ref.watch(taskTemplateRepositoryProvider),
    metricOrchestrator: ref.watch(metricOrchestratorProvider),
  );
});
