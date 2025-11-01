import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/focus_session.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../data/models/task_template.dart';
import '../services/focus_flow_service.dart';
import '../services/metric_orchestrator.dart';
import '../services/preference_service.dart';
import '../services/task_hierarchy_service.dart';
import '../services/task_service.dart';
import '../services/task_template_service.dart';
import '../constants/task_constants.dart';
import '../monetization/monetization_service.dart';
import '../monetization/monetization_state.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

final appLocaleProvider = StreamProvider<Locale>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) {
        final parts = pref.localeCode.split('_');
        if (parts.length == 2) {
          return Locale(parts[0], parts[1]);
        } else {
          return Locale(pref.localeCode);
        }
      });
});

final themeProvider = StreamProvider<ThemeMode>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) => pref.themeMode);
});

final fontScaleProvider = StreamProvider<double>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) => pref.fontScale);
});

final seedInitializerProvider = FutureProvider<void>((ref) async {
  ref.keepAlive();
  final service = ref.watch(seedImportServiceProvider);
  
  // 等待 appLocaleProvider 加载完成，而不是使用默认值
  final localeAsync = ref.watch(appLocaleProvider);
  final localeValue = await localeAsync.when(
    data: (value) => Future.value(value),
    loading: () async {
      // 如果还在加载，直接从 PreferenceRepository 加载
      final pref = await ref.read(preferenceRepositoryProvider).load();
      final parts = pref.localeCode.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      } else {
        return Locale(pref.localeCode);
      }
    },
    error: (_, __) => Future.value(const Locale('en')),
  );
  
  // 构造完整的 locale 代码 (如 zh_CN, zh_HK, en)
  final locale = localeValue.countryCode != null
      ? '${localeValue.languageCode}_${localeValue.countryCode}'
      : localeValue.languageCode;
  
  debugPrint('SeedInitializer: locale = $locale');
  await service.importIfNeeded(locale);
});

final navigationIndexProvider = StateProvider<int>((ref) => 0);

final metricSnapshotProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(metricOrchestratorProvider).latest();
});

class MetricRefreshNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  MetricOrchestrator get _orchestrator => ref.read(metricOrchestratorProvider);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _orchestrator.requestRecompute(MetricRecomputeReason.task),
    );
  }
}

final metricRefreshNotifierProvider =
    AsyncNotifierProvider<MetricRefreshNotifier, void>(() {
      return MetricRefreshNotifier();
    });

final taskSectionsProvider = StreamProvider.family<List<Task>, TaskSection>((
  ref,
  section,
) {
  return ref.watch(taskRepositoryProvider).watchSection(section);
});

@immutable
class InboxFilterState {
  const InboxFilterState({
    this.contextTag,
    this.priorityTag,
    this.urgencyTag,
    this.importanceTag,
  });

  final String? contextTag;
  final String? priorityTag;
  final String? urgencyTag;
  final String? importanceTag;

  bool get hasFilters =>
      (contextTag != null && contextTag!.isNotEmpty) ||
      (priorityTag != null && priorityTag!.isNotEmpty) ||
      (urgencyTag != null && urgencyTag!.isNotEmpty) ||
      (importanceTag != null && importanceTag!.isNotEmpty);

  InboxFilterState copyWith({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
  }) {
    return InboxFilterState(
      contextTag: contextTag ?? this.contextTag,
      priorityTag: priorityTag ?? this.priorityTag,
      urgencyTag: urgencyTag ?? this.urgencyTag,
      importanceTag: importanceTag ?? this.importanceTag,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is InboxFilterState &&
        other.contextTag == contextTag &&
        other.priorityTag == priorityTag &&
        other.urgencyTag == urgencyTag &&
        other.importanceTag == importanceTag;
  }

  @override
  int get hashCode => Object.hash(contextTag, priorityTag, urgencyTag, importanceTag);
}

class InboxFilterNotifier extends StateNotifier<InboxFilterState> {
  InboxFilterNotifier() : super(const InboxFilterState());

  void setContextTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.contextTag == normalized) {
      return;
    }
    state = state.copyWith(contextTag: normalized);
  }

  void setPriorityTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.priorityTag == normalized) {
      return;
    }
    state = state.copyWith(priorityTag: normalized);
  }

  void setUrgencyTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.urgencyTag == normalized) {
      return;
    }
    state = state.copyWith(urgencyTag: normalized);
  }

  void setImportanceTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.importanceTag == normalized) {
      return;
    }
    state = state.copyWith(importanceTag: normalized);
  }

  void reset() {
    state = const InboxFilterState();
  }
}

final inboxFilterProvider =
    StateNotifierProvider<InboxFilterNotifier, InboxFilterState>((ref) {
      return InboxFilterNotifier();
    });

final inboxTasksProvider = StreamProvider<List<Task>>((ref) {
  final filter = ref.watch(inboxFilterProvider);
  return ref.watch(taskRepositoryProvider).watchInboxFiltered(
        contextTag: filter.contextTag,
        priorityTag: filter.priorityTag,
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
      );
});

final rootTasksProvider = FutureProvider<List<Task>>((ref) async {
  return ref.watch(taskRepositoryProvider).listRoots();
});

final projectsProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchProjects();
});

final quickTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchQuickTasks();
});

final projectMilestonesProvider =
    StreamProvider.family<List<Task>, int>((ref, projectId) {
      return ref.watch(taskRepositoryProvider).watchMilestones(projectId);
    });

/// Provider for getting the parent task of a task (could be project or milestone)
final taskParentProvider = FutureProvider.family<Task?, int>((ref, taskId) async {
  final task = await ref.watch(taskRepositoryProvider).findById(taskId);
  if (task?.parentId == null) return null;
  return ref.watch(taskRepositoryProvider).findById(task!.parentId!);
});

/// Provider for getting the complete hierarchy of a task (project and milestone if applicable)
@immutable
class TaskProjectHierarchy {
  const TaskProjectHierarchy({
    required this.project,
    this.milestone,
  });

  final Task project;
  final Task? milestone;

  bool get hasMilestone => milestone != null;
}

final taskProjectHierarchyProvider =
    FutureProvider.family<TaskProjectHierarchy?, int>((ref, taskId) async {
  final task = await ref.watch(taskRepositoryProvider).findById(taskId);
  if (task == null || task.parentId == null) return null;

  final parent = await ref.watch(taskRepositoryProvider).findById(task.parentId!);
  if (parent == null) return null;

  // If parent is a project, return just the project
  if (parent.taskKind == TaskKind.project) {
    return TaskProjectHierarchy(project: parent);
  }

  // If parent is a milestone, get its project
  if (parent.taskKind == TaskKind.milestone && parent.parentId != null) {
    final project = await ref.watch(taskRepositoryProvider).findById(parent.parentId!);
    if (project != null && project.taskKind == TaskKind.project) {
      return TaskProjectHierarchy(project: project, milestone: parent);
    }
  }

  return null;
});

final taskTreeProvider = StreamProvider.family<TaskTreeNode, int>((
  ref,
  rootId,
) {
  return ref.watch(taskRepositoryProvider).watchTaskTree(rootId);
});

final expandedRootTaskIdProvider = StateProvider<int?>((ref) => null);

/// Provider for managing expanded task ID in task list page
final taskListExpandedTaskIdProvider = StateProvider<int?>((ref) => null);
final inboxExpandedTaskIdProvider = StateProvider<Set<int>>((ref) => <int>{});
final projectsExpandedTaskIdProvider = StateProvider<int?>((ref) => null);

/// Provider for managing quick tasks section expanded state
/// true = expanded, false = collapsed, defaults to false
final quickTasksExpandedProvider = StateProvider<bool>((ref) => false);

class TaskEditActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  TaskService get _taskService => ref.read(taskServiceProvider);
  TaskHierarchyService get _hierarchyService =>
      ref.read(taskHierarchyServiceProvider);

  Future<void> addSubtask({
    required int parentId,
    required String title,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final subtask = await _taskService.captureInboxTask(title: title);
      await _hierarchyService.moveToParent(
        taskId: subtask.id,
        parentId: parentId,
        sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
      );
      await _taskService.updateDetails(
        taskId: subtask.id,
        payload: const TaskUpdate(status: TaskStatus.pending),
      );
    });
  }

  Future<void> editTitle({required int taskId, required String title}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _taskService.updateDetails(
        taskId: taskId,
        payload: TaskUpdate(title: title),
      );
    });
  }

  Future<void> archive(int taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _taskService.archive(taskId));
  }
}

final taskEditActionsNotifierProvider =
    AsyncNotifierProvider<TaskEditActionsNotifier, void>(() {
      return TaskEditActionsNotifier();
    });

class FocusActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  FocusFlowService get _focusFlowService => ref.read(focusFlowServiceProvider);

  Future<void> start(int taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _focusFlowService.startFocus(taskId: taskId);
    });
  }

  Future<void> end({
    required int sessionId,
    required FocusOutcome outcome,
    String? reflection,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _focusFlowService.endFocus(
        sessionId: sessionId,
        outcome: outcome,
        reflectionNote: reflection,
      );
    });
  }
}

final focusActionsNotifierProvider =
    AsyncNotifierProvider<FocusActionsNotifier, void>(() {
      return FocusActionsNotifier();
    });

final focusSessionProvider = StreamProvider.family<FocusSession?, int>((
  ref,
  taskId,
) {
  return ref.watch(focusFlowServiceProvider).watchActive(taskId);
});

final templateSuggestionsProvider =
    FutureProvider.family<List<TaskTemplate>, TemplateSuggestionQuery>((
      ref,
      query,
    ) async {
      try {
        final service = ref.watch(taskTemplateServiceProvider);
        if (query.text?.isNotEmpty == true) {
          return await service.search(query.text!, limit: query.limit);
        }
        return await service.listRecent(query.limit);
      } catch (error) {
        debugPrint('TemplateSuggestionsProvider error: $error');
        return <TaskTemplate>[]; // 返回空列表而不是抛出错误
      }
    });

final contextTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    return await ref.watch(taskServiceProvider).listTagsByKind(TagKind.context);
  } catch (error) {
    debugPrint('ContextTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final priorityTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    return await ref.watch(taskServiceProvider).listTagsByKind(TagKind.priority);
  } catch (error) {
    debugPrint('PriorityTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final urgencyTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    return await ref.watch(taskServiceProvider).listTagsByKind(TagKind.urgency);
  } catch (error) {
    debugPrint('UrgencyTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final importanceTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    // 依赖种子初始化：导入完成后会刷新本 Provider
    ref.watch(seedInitializerProvider);
    return await ref.watch(taskServiceProvider).listTagsByKind(TagKind.importance);
  } catch (error) {
    debugPrint('ImportanceTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final executionTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    ref.watch(seedInitializerProvider);
    return await ref.watch(taskServiceProvider).listTagsByKind(TagKind.execution);
  } catch (error) {
    debugPrint('ExecutionTagOptionsProvider error: $error');
    return <Tag>[];
  }
});

final monetizationStateProvider = StreamProvider<MonetizationState>((ref) {
  return ref.watch(monetizationServiceProvider).watch();
});

class MonetizationActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  MonetizationService get _service => ref.read(monetizationServiceProvider);

  Future<void> startTrial({Duration duration = const Duration(days: 7)}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _service.startTrial(duration: duration);
    });
  }

  Future<void> activateSubscription() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _service.activateSubscription();
    });
  }

  Future<void> cancelSubscription() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _service.cancelSubscription();
    });
  }

  void registerPremiumHit() {
    _service.registerPremiumHit();
  }
}

final monetizationActionsNotifierProvider =
    AsyncNotifierProvider<MonetizationActionsNotifier, void>(() {
      return MonetizationActionsNotifier();
    });

class TemplateSuggestionQuery {
  const TemplateSuggestionQuery({this.text, this.limit = 5});

  final String? text;
  final int limit;
}

class TemplateActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  TaskTemplateService get _service => ref.read(taskTemplateServiceProvider);

  Future<void> create(TaskTemplateDraft draft) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.createTemplate(draft));
  }

  Future<void> delete(int templateId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.deleteTemplate(templateId));
  }
}

final templateActionsNotifierProvider =
    AsyncNotifierProvider<TemplateActionsNotifier, void>(() {
      return TemplateActionsNotifier();
    });

class PreferenceActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  PreferenceService get _service => ref.read(preferenceServiceProvider);

  Future<void> updateLocale(String localeCode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateLocale(localeCode));
  }

  Future<void> updateTheme(ThemeMode mode) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateTheme(mode));
  }

  Future<void> updateFontScale(double scale) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateFontScale(scale));
  }
}

final preferenceActionsNotifierProvider =
    AsyncNotifierProvider<PreferenceActionsNotifier, void>(() {
      return PreferenceActionsNotifier();
    });
