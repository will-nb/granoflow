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
import '../../data/repositories/drift/drift_focus_session_repository.dart';
import '../../data/repositories/drift/drift_milestone_repository.dart';
import '../../data/repositories/drift/drift_preference_repository.dart';
import '../../data/repositories/drift/drift_project_repository.dart';
import '../../data/repositories/drift/drift_seed_repository.dart';
import '../../data/repositories/drift/drift_tag_repository.dart';
import '../../data/repositories/drift/drift_task_repository.dart';
import '../../data/repositories/drift/drift_task_template_repository.dart';
import '../../core/config/database_config.dart';
import 'package:objectbox/objectbox.dart';

/// ObjectBox Store Provider（仅在需要 ObjectBox 时使用）
final objectBoxStoreProvider = Provider<Store?>((ref) => null);

/// DatabaseAdapter Provider，根据 DatabaseConfig.current 创建对应的 adapter
final databaseAdapterProvider = FutureProvider<DatabaseAdapter>((ref) async {
  final store = ref.watch(objectBoxStoreProvider);
  
  return await DatabaseConfig.createAdapter(
    objectBoxStore: store,
  );
});

/// 根据当前数据库类型创建 TaskRepository
final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final adapter = await ref.read(databaseAdapterProvider.future);
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxTaskRepository(adapter);
    case DatabaseType.drift:
      return DriftTaskRepository(adapter);
  }
});

/// 根据当前数据库类型创建 ProjectRepository
final projectRepositoryProvider = FutureProvider<ProjectRepository>((ref) async {
  final adapterAsync = ref.watch(databaseAdapterProvider);
  final adapter = await adapterAsync.requireValue;
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxProjectRepository(adapter);
    case DatabaseType.drift:
      return DriftProjectRepository(adapter);
  }
});

/// 根据当前数据库类型创建 MilestoneRepository
final milestoneRepositoryProvider = FutureProvider<MilestoneRepository>((ref) async {
  final adapterAsync = ref.watch(databaseAdapterProvider);
  final adapter = await adapterAsync.requireValue;
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxMilestoneRepository(adapter);
    case DatabaseType.drift:
      return DriftMilestoneRepository(adapter);
  }
});

/// 根据当前数据库类型创建 FocusSessionRepository
final focusSessionRepositoryProvider = FutureProvider<FocusSessionRepository>((ref) async {
  final adapterAsync = ref.watch(databaseAdapterProvider);
  final adapter = await adapterAsync.requireValue;
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxFocusSessionRepository(adapter);
    case DatabaseType.drift:
      return DriftFocusSessionRepository(adapter);
  }
});

/// 根据当前数据库类型创建 TagRepository
final tagRepositoryProvider = FutureProvider<TagRepository>((ref) async {
  final adapterAsync = ref.watch(databaseAdapterProvider);
  final adapter = await adapterAsync.requireValue;
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxTagRepository(adapter);
    case DatabaseType.drift:
      return DriftTagRepository(adapter);
  }
});

/// 根据当前数据库类型创建 PreferenceRepository
final preferenceRepositoryProvider = FutureProvider<PreferenceRepository>((ref) async {
  final adapterAsync = ref.watch(databaseAdapterProvider);
  final adapter = await adapterAsync.requireValue;
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxPreferenceRepository(adapter);
    case DatabaseType.drift:
      return DriftPreferenceRepository(adapter);
  }
});

/// MetricRepository 不依赖数据库，使用内存实现
final metricRepositoryProvider = Provider<MetricRepository>((ref) {
  return InMemoryMetricRepository();
});

/// 根据当前数据库类型创建 TaskTemplateRepository
final taskTemplateRepositoryProvider = FutureProvider<TaskTemplateRepository>((ref) async {
  final adapterAsync = ref.watch(databaseAdapterProvider);
  final adapter = await adapterAsync.requireValue;
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxTaskTemplateRepository(adapter);
    case DatabaseType.drift:
      return DriftTaskTemplateRepository(adapter);
  }
});

/// 根据当前数据库类型创建 SeedRepository
final seedRepositoryProvider = FutureProvider<SeedRepository>((ref) async {
  final adapterAsync = ref.watch(databaseAdapterProvider);
  final adapter = await adapterAsync.requireValue;
  final type = await DatabaseConfig.current;
  
  switch (type) {
    case DatabaseType.objectbox:
      return ObjectBoxSeedRepository(adapter);
    case DatabaseType.drift:
      return DriftSeedRepository(adapter);
  }
});
