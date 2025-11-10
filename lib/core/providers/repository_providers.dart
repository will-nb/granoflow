import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database_adapter.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/metric_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';
import '../../data/repositories/objectbox/objectbox_focus_session_repository.dart';
import '../../data/repositories/objectbox/objectbox_milestone_repository.dart';
import '../../data/repositories/objectbox/objectbox_preference_repository.dart';
import '../../data/repositories/objectbox/objectbox_project_repository.dart';
import '../../data/repositories/objectbox/objectbox_seed_repository.dart';
import '../../data/repositories/objectbox/objectbox_tag_repository.dart';
import '../../data/repositories/objectbox/objectbox_task_repository.dart';
import '../../data/repositories/objectbox/objectbox_task_template_repository.dart';
// TODO: 在阶段 3.7 启用这些导入，用于切换到 Drift
// import '../../data/repositories/drift/drift_focus_session_repository.dart';
// import '../../data/repositories/drift/drift_milestone_repository.dart';
// import '../../data/repositories/drift/drift_preference_repository.dart';
// import '../../data/repositories/drift/drift_project_repository.dart';
// import '../../data/repositories/drift/drift_seed_repository.dart';
// import '../../data/repositories/drift/drift_tag_repository.dart';
// import '../../data/repositories/drift/drift_task_repository.dart';
// import '../../data/repositories/drift/drift_task_template_repository.dart';
// import '../../core/config/database_config.dart';

final databaseAdapterProvider = Provider<DatabaseAdapter>((ref) {
  throw UnimplementedError('DatabaseAdapter instance has not been provided');
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return ObjectBoxTaskRepository(ref.watch(databaseAdapterProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ObjectBoxProjectRepository(ref.watch(databaseAdapterProvider));
});

final milestoneRepositoryProvider = Provider<MilestoneRepository>((ref) {
  return ObjectBoxMilestoneRepository(ref.watch(databaseAdapterProvider));
});

final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return ObjectBoxFocusSessionRepository(ref.watch(databaseAdapterProvider));
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return ObjectBoxTagRepository(ref.watch(databaseAdapterProvider));
});

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return ObjectBoxPreferenceRepository(ref.watch(databaseAdapterProvider));
});

final metricRepositoryProvider = Provider<MetricRepository>((ref) {
  return InMemoryMetricRepository();
});

final taskTemplateRepositoryProvider = Provider<TaskTemplateRepository>((ref) {
  return ObjectBoxTaskTemplateRepository(ref.watch(databaseAdapterProvider));
});

final seedRepositoryProvider = Provider<SeedRepository>((ref) {
  return ObjectBoxSeedRepository(ref.watch(databaseAdapterProvider));
});
