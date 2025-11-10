import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/metric_repository.dart';
import '../../data/repositories/preference_repository.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/seed_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/task_template_repository.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar instance has not been provided');
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return IsarTaskRepository(ref.watch(isarProvider));
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return IsarProjectRepository(ref.watch(isarProvider));
});

final milestoneRepositoryProvider = Provider<MilestoneRepository>((ref) {
  return IsarMilestoneRepository(ref.watch(isarProvider));
});

final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  return IsarFocusSessionRepository(ref.watch(isarProvider));
});

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return IsarTagRepository(ref.watch(isarProvider));
});

final preferenceRepositoryProvider = Provider<PreferenceRepository>((ref) {
  return IsarPreferenceRepository(ref.watch(isarProvider));
});

final metricRepositoryProvider = Provider<MetricRepository>((ref) {
  return InMemoryMetricRepository();
});

final taskTemplateRepositoryProvider = Provider<TaskTemplateRepository>((ref) {
  return IsarTaskTemplateRepository(ref.watch(isarProvider));
});

final seedRepositoryProvider = Provider<SeedRepository>((ref) {
  return IsarSeedRepository(ref.watch(isarProvider));
});
