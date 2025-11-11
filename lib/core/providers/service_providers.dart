import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/encryption_key_service.dart';
import '../services/export_encryption_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/focus_flow_service.dart';
import '../services/metric_orchestrator.dart';
import '../services/preference_service.dart';
import '../services/seed_import_service.dart';
import '../services/milestone_service.dart';
import '../services/project_service.dart';
import '../services/task_hierarchy_service.dart';
import '../services/task_service.dart';
import '../services/sort_index_service.dart';
import '../services/task_template_service.dart';
import '../services/clock_audio_service.dart';
import '../services/calendar_review_service.dart';
import '../services/heatmap_color_service.dart';
import '../monetization/monetization_service.dart';
import 'repository_providers.dart';

final metricOrchestratorProvider = FutureProvider<MetricOrchestrator>((ref) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final focusRepository = await ref.read(focusSessionRepositoryProvider.future);
  return MetricOrchestrator(
    metricRepository: ref.read(metricRepositoryProvider),
    taskRepository: taskRepository,
    focusRepository: focusRepository,
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

final sortIndexServiceProvider = FutureProvider<SortIndexService>((ref) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  return SortIndexService(taskRepository: taskRepository);
});

final taskServiceProvider = FutureProvider<TaskService>((ref) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final tagRepository = await ref.read(tagRepositoryProvider.future);
  final metricOrchestrator = await ref.read(metricOrchestratorProvider.future);
  final focusSessionRepository = await ref.read(focusSessionRepositoryProvider.future);
  final sortIndexService = await ref.read(sortIndexServiceProvider.future);
  final clockAudioService = await ref.read(clockAudioServiceProvider.future);
  final preferenceService = await ref.read(preferenceServiceProvider.future);
  return TaskService(
    taskRepository: taskRepository,
    tagRepository: tagRepository,
    metricOrchestrator: metricOrchestrator,
    focusSessionRepository: focusSessionRepository,
    sortIndexService: sortIndexService,
    clockAudioService: clockAudioService,
    preferenceService: preferenceService,
  );
});

final projectServiceProvider = FutureProvider<ProjectService>((ref) async {
  final projectRepository = await ref.read(projectRepositoryProvider.future);
  final milestoneRepository = await ref.read(milestoneRepositoryProvider.future);
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final metricOrchestrator = await ref.read(metricOrchestratorProvider.future);
  return ProjectService(
    projectRepository: projectRepository,
    milestoneRepository: milestoneRepository,
    taskRepository: taskRepository,
    metricOrchestrator: metricOrchestrator,
  );
});

final milestoneServiceProvider = FutureProvider<MilestoneService>((ref) async {
  final milestoneRepository = await ref.read(milestoneRepositoryProvider.future);
  return MilestoneService(
    milestoneRepository: milestoneRepository,
  );
});

final taskHierarchyServiceProvider = FutureProvider<TaskHierarchyService>((ref) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final metricOrchestrator = await ref.read(metricOrchestratorProvider.future);
  return TaskHierarchyService(
    taskRepository: taskRepository,
    metricOrchestrator: metricOrchestrator,
  );
});

final focusFlowServiceProvider = FutureProvider<FocusFlowService>((ref) async {
  final focusRepository = await ref.read(focusSessionRepositoryProvider.future);
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final taskService = await ref.read(taskServiceProvider.future);
  final metricOrchestrator = await ref.read(metricOrchestratorProvider.future);
  return FocusFlowService(
    focusRepository: focusRepository,
    taskRepository: taskRepository,
    taskService: taskService,
    metricOrchestrator: metricOrchestrator,
  );
});

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  final service = MonetizationService();
  ref.onDispose(service.dispose);
  return service;
});

final taskTemplateServiceProvider = FutureProvider<TaskTemplateService>((ref) async {
  final templateRepository = await ref.read(taskTemplateRepositoryProvider.future);
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final taskService = await ref.read(taskServiceProvider.future);
  return TaskTemplateService(
    templateRepository: templateRepository,
    taskRepository: taskRepository,
    taskService: taskService,
  );
});

final preferenceServiceProvider = FutureProvider<PreferenceService>((ref) async {
  final repository = await ref.read(preferenceRepositoryProvider.future);
  return PreferenceService(repository: repository);
});

final seedImportServiceProvider = FutureProvider<SeedImportService>((ref) async {
  final seedRepository = await ref.read(seedRepositoryProvider.future);
  final tagRepository = await ref.read(tagRepositoryProvider.future);
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final templateRepository = await ref.read(taskTemplateRepositoryProvider.future);
  final projectService = await ref.read(projectServiceProvider.future);
  final milestoneRepository = await ref.read(milestoneRepositoryProvider.future);
  final metricOrchestrator = await ref.read(metricOrchestratorProvider.future);
  return SeedImportService(
    seedRepository: seedRepository,
    tagRepository: tagRepository,
    taskRepository: taskRepository,
    templateRepository: templateRepository,
    projectService: projectService,
    milestoneRepository: milestoneRepository,
    metricOrchestrator: metricOrchestrator,
  );
});

final clockAudioServiceProvider = FutureProvider<ClockAudioService>((ref) async {
  final preferenceService = await ref.read(preferenceServiceProvider.future);
  final service = ClockAudioService(
    preferenceService: preferenceService,
  );
  ref.onDispose(service.dispose);
  return service;
});

final calendarReviewServiceProvider = FutureProvider<CalendarReviewService>((ref) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final focusSessionRepository = await ref.read(focusSessionRepositoryProvider.future);
  return CalendarReviewService(
    taskRepository: taskRepository,
    focusSessionRepository: focusSessionRepository,
  );
});

final heatmapColorServiceProvider = FutureProvider<HeatmapColorService>((ref) async {
  return await HeatmapColorService.getInstance();
});

final exportServiceProvider = FutureProvider<ExportService>((ref) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final projectRepository = await ref.read(projectRepositoryProvider.future);
  final milestoneRepository = await ref.read(milestoneRepositoryProvider.future);
  final encryptionService = ref.read(exportEncryptionServiceProvider);
  final keyService = ref.read(encryptionKeyServiceProvider);
  return ExportService(
    taskRepository: taskRepository,
    projectRepository: projectRepository,
    milestoneRepository: milestoneRepository,
    encryptionService: encryptionService,
    encryptionKeyService: keyService,
  );
});

final importServiceProvider = FutureProvider<ImportService>((ref) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final projectRepository = await ref.read(projectRepositoryProvider.future);
  final milestoneRepository = await ref.read(milestoneRepositoryProvider.future);
  final encryptionService = ref.read(exportEncryptionServiceProvider);
  final keyService = ref.read(encryptionKeyServiceProvider);
  return ImportService(
    taskRepository: taskRepository,
    projectRepository: projectRepository,
    milestoneRepository: milestoneRepository,
    encryptionService: encryptionService,
    encryptionKeyService: keyService,
  );
});

final encryptionKeyServiceProvider = Provider<EncryptionKeyService>((ref) {
  return EncryptionKeyService();
});

final exportEncryptionServiceProvider = Provider<ExportEncryptionService>((ref) {
  return ExportEncryptionService();
});
