import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/focus_session.dart';
import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
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
import '../../data/repositories/task_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
import '../constants/font_scale_level.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

final appLocaleProvider = StreamProvider<Locale>((ref) {
  return ref.watch(preferenceServiceProvider).watch().map((pref) {
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

final fontScaleLevelProvider = StreamProvider<FontScaleLevel>((ref) {
  return ref
      .watch(preferenceServiceProvider)
      .watch()
      .map((pref) => pref.fontScaleLevel);
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

/// 通用任务筛选状态
/// 
/// 包含标签筛选和项目筛选的所有字段
@immutable
class TaskFilterState {
  const TaskFilterState({
    this.contextTag,
    this.priorityTag,
    this.urgencyTag,
    this.importanceTag,
    this.projectId,
    this.milestoneId,
    this.showNoProject = false,
  });

  /// 场景标签筛选
  final String? contextTag;
  
  /// 优先级标签筛选（保留，用于兼容，实际使用urgencyTag和importanceTag）
  @Deprecated('使用urgencyTag和importanceTag替代')
  final String? priorityTag;
  
  /// 紧急度标签筛选
  final String? urgencyTag;
  
  /// 重要度标签筛选
  final String? importanceTag;
  
  /// 项目ID筛选
  final String? projectId;
  
  /// 里程碑ID筛选（仅在projectId不为空时有效）
  final String? milestoneId;
  
  /// 是否只显示无项目的任务
  final bool showNoProject;

  bool get hasFilters =>
      (contextTag != null && contextTag!.isNotEmpty) ||
      // priorityTag 已废弃，不再用于筛选检查
      (urgencyTag != null && urgencyTag!.isNotEmpty) ||
      (importanceTag != null && importanceTag!.isNotEmpty) ||
      (projectId != null && projectId!.isNotEmpty) ||
      (milestoneId != null && milestoneId!.isNotEmpty) ||
      showNoProject;

  TaskFilterState copyWith({
    String? contextTag,
    @Deprecated('使用urgencyTag和importanceTag替代')
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) {
    // ignore: deprecated_member_use_from_same_package
    return TaskFilterState(
      contextTag: contextTag ?? this.contextTag,
      // ignore: deprecated_member_use_from_same_package
      priorityTag: priorityTag ?? this.priorityTag,
      urgencyTag: urgencyTag ?? this.urgencyTag,
      importanceTag: importanceTag ?? this.importanceTag,
      projectId: projectId ?? this.projectId,
      milestoneId: milestoneId ?? this.milestoneId,
      showNoProject: showNoProject ?? this.showNoProject,
    );
  }

  @override
  bool operator ==(Object other) {
    // ignore: deprecated_member_use_from_same_package
    return other is TaskFilterState &&
        other.contextTag == contextTag &&
        // ignore: deprecated_member_use_from_same_package
        other.priorityTag == priorityTag &&
        other.urgencyTag == urgencyTag &&
        other.importanceTag == importanceTag &&
        other.projectId == projectId &&
        other.milestoneId == milestoneId &&
        other.showNoProject == showNoProject;
  }

  @override
  int get hashCode => Object.hash(
        contextTag,
        // ignore: deprecated_member_use_from_same_package
        priorityTag,
        urgencyTag,
        importanceTag,
        projectId,
        milestoneId,
        showNoProject,
      );
}

/// 通用任务筛选Notifier
class TaskFilterNotifier extends StateNotifier<TaskFilterState> {
  TaskFilterNotifier() : super(const TaskFilterState());

  void setContextTag(String? tag) {
    final normalized = (tag != null && tag.isEmpty) ? null : tag;
    if (state.contextTag == normalized) {
      return;
    }
    state = state.copyWith(contextTag: normalized);
  }

  @Deprecated('使用urgencyTag和importanceTag替代')
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

  void setProjectId(String? projectId) {
    if (state.projectId == projectId) {
      return;
    }
    // 如果切换项目，清除里程碑筛选
    state = state.copyWith(
      projectId: projectId,
      milestoneId: projectId == null ? null : state.milestoneId,
      showNoProject: false, // 选择项目时，关闭"无项目"筛选
    );
  }

  void setMilestoneId(String? milestoneId) {
    if (state.milestoneId == milestoneId) {
      return;
    }
    state = state.copyWith(milestoneId: milestoneId);
  }

  void toggleShowNoProject() {
    state = state.copyWith(
      showNoProject: !state.showNoProject,
      projectId: state.showNoProject ? state.projectId : null, // 开启"无项目"时，清除项目筛选
      milestoneId: state.showNoProject ? state.milestoneId : null,
    );
  }

  void reset() {
    state = const TaskFilterState();
  }
}

/// Inbox筛选状态（向后兼容）
/// 
/// 作为TaskFilterState的别名，保持向后兼容
@Deprecated('使用TaskFilterState替代')
typedef InboxFilterState = TaskFilterState;

/// Inbox筛选Notifier（向后兼容）
/// 
/// 继承TaskFilterNotifier，保持向后兼容
class InboxFilterNotifier extends TaskFilterNotifier {
  InboxFilterNotifier() : super();
}

/// Inbox筛选Provider（向后兼容）
/// 
/// 继续使用InboxFilterNotifier和InboxFilterState，但内部实现使用通用类
final inboxFilterProvider =
    StateNotifierProvider<InboxFilterNotifier, TaskFilterState>((ref) {
      return InboxFilterNotifier();
    });

/// 已完成任务筛选Provider
final completedTasksFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
      return TaskFilterNotifier();
    });

/// 已归档任务筛选Provider
final archivedTasksFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
      return TaskFilterNotifier();
    });

/// 已删除任务筛选Provider
final trashedTasksFilterProvider =
    StateNotifierProvider<TaskFilterNotifier, TaskFilterState>((ref) {
      return TaskFilterNotifier();
    });

final inboxTasksProvider = StreamProvider<List<Task>>((ref) {
  final filter = ref.watch(inboxFilterProvider);
  return ref
      .watch(taskRepositoryProvider)
      .watchInboxFiltered(
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );
});

/// 辅助函数：计算任务列表的 level 映射
///
/// [tasks] 任务列表
/// [repository] 任务仓库
/// 返回 taskId -> level 的映射（level = depth + 1）
Future<Map<int, int>> _calculateTaskLevelMap(
  List<Task> tasks,
  TaskRepository repository,
) async {
  final levelMap = <int, int>{};

  // 批量计算所有任务的 level
  for (final task in tasks) {
    final depth = await calculateHierarchyDepth(task, repository);
    levelMap[task.id] = depth + 1;
  }

  return levelMap;
}

/// Provider for getting task level map (虚拟字段)
///
/// 返回 taskId -> level 的映射，level 是计算属性（虚拟字段）
/// 自动响应 inboxTasksProvider 的变化
///
/// 使用方式：
/// ```dart
/// final levelMapAsync = ref.watch(inboxTaskLevelMapProvider);
/// return levelMapAsync.when(
///   data: (levelMap) {
///     final taskLevel = levelMap[task.id] ?? 1;
///     // ...
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => SizedBox.shrink(),
/// );
/// ```
final inboxTaskLevelMapProvider = FutureProvider<Map<int, int>>((ref) async {
  final tasksAsync = ref.watch(inboxTasksProvider);
  final tasks = await tasksAsync.requireValue;
  final taskRepository = ref.watch(taskRepositoryProvider);
  return _calculateTaskLevelMap(tasks, taskRepository);
});

/// 通用的任务 level 映射 Provider (Family)
///
/// 接受任务列表作为参数，返回 taskId -> level 的映射
/// 可以在任何页面使用，统一计算任务的 level（虚拟字段）
///
/// 使用方式：
/// ```dart
/// final tasksAsync = ref.watch(someTaskListProvider);
/// final levelMapAsync = tasksAsync.when(
///   data: (tasks) => ref.watch(taskLevelMapProvider(tasks)),
///   loading: () => const AsyncLoading<Map<int, int>>(),
///   error: (_, __) => const AsyncError<Map<int, int>>(null, StackTrace.empty),
/// );
/// ```
final taskLevelMapProvider = FutureProvider.family<Map<int, int>, List<Task>>((
  ref,
  tasks,
) async {
  final taskRepository = ref.watch(taskRepositoryProvider);
  return _calculateTaskLevelMap(tasks, taskRepository);
});

/// 辅助函数：递归获取所有后代任务 ID
Future<Set<int>> _getAllDescendants(
  int taskId,
  TaskRepository repository,
) async {
  final result = <int>{};
  final children = await repository.listChildren(taskId);
  final normalChildren = children
      .where((t) => !isProjectOrMilestone(t))
      .toList();

  for (final child in normalChildren) {
    result.add(child.id);
    result.addAll(await _getAllDescendants(child.id, repository));
  }

  return result;
}

/// Provider for getting task children map (虚拟字段)
///
/// 返回 taskId -> Set<子任务ID> 的映射
/// 自动响应 inboxTasksProvider 的变化
///
/// 使用方式：
/// ```dart
/// final childrenMapAsync = ref.watch(inboxTaskChildrenMapProvider);
/// return childrenMapAsync.when(
///   data: (childrenMap) {
///     final childTaskIds = childrenMap[task.id] ?? <int>{};
///     // ...
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => SizedBox.shrink(),
/// );
/// ```
final inboxTaskChildrenMapProvider = FutureProvider<Map<int, Set<int>>>((
  ref,
) async {
  final tasksAsync = ref.watch(inboxTasksProvider);
  final tasks = await tasksAsync.requireValue;
  final taskRepository = ref.watch(taskRepositoryProvider);
  final childrenMap = <int, Set<int>>{};

  // 为每个任务查找所有子任务
  for (final task in tasks) {
    final children = await taskRepository.listChildren(task.id);
    final normalChildren = children
        .where((t) => !isProjectOrMilestone(t))
        .map((t) => t.id)
        .toSet();

    // 递归添加子任务的子任务
    final allChildren = <int>{...normalChildren};
    for (final childId in normalChildren) {
      final childChildren = await _getAllDescendants(childId, taskRepository);
      allChildren.addAll(childChildren);
    }

    childrenMap[task.id] = allChildren;
  }

  return childrenMap;
});

final rootTasksProvider = FutureProvider<List<Task>>((ref) async {
  return ref.watch(taskRepositoryProvider).listRoots();
});

final projectsDomainProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectServiceProvider).watchActiveProjects();
});

final projectMilestonesDomainProvider =
    StreamProvider.family<List<Milestone>, String>((ref, projectId) {
      return ref.watch(projectServiceProvider).watchMilestones(projectId);
    });

final milestoneTasksProvider = StreamProvider.family<List<Task>, String>((
  ref,
  milestoneId,
) {
  return ref.watch(taskRepositoryProvider).watchTasksByMilestoneId(milestoneId);
});

final quickTasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchQuickTasks();
});

/// Provider for getting the parent task of a task (could be project or milestone)
final taskParentProvider = FutureProvider.family<Task?, int>((
  ref,
  taskId,
) async {
  final task = await ref.watch(taskRepositoryProvider).findById(taskId);
  if (task?.parentId == null) return null;
  return ref.watch(taskRepositoryProvider).findById(task!.parentId!);
});

/// Provider for getting the complete hierarchy of a task (project and milestone if applicable)
@immutable
class TaskProjectHierarchy {
  const TaskProjectHierarchy({required this.project, this.milestone});

  final Project project;
  final Milestone? milestone;

  bool get hasMilestone => milestone != null;
}

final taskProjectHierarchyProvider =
    StreamProvider.family<TaskProjectHierarchy?, int>((ref, taskId) async* {
      // 使用 watchTaskById 监听任务变化，这样当任务的项目/里程碑字段更新时，会自动触发
      final taskStream = ref.watch(taskRepositoryProvider).watchTaskById(taskId);
      await for (final task in taskStream) {
        if (task == null) {
          yield null;
          continue;
        }

        final projectId = task.projectId;
        if (projectId == null || projectId.isEmpty) {
          yield null;
          continue;
        }

        final projectService = ref.watch(projectServiceProvider);
        final project = await projectService.findByProjectId(projectId);
        if (project == null) {
          yield null;
          continue;
        }

        Milestone? milestone;
        final milestoneId = task.milestoneId;
        if (milestoneId != null && milestoneId.isNotEmpty) {
          milestone = await projectService.findMilestoneById(milestoneId);
        }

        yield TaskProjectHierarchy(project: project, milestone: milestone);
      }
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

/// Provider for managing expanded task IDs in tasks section (按分区管理)
///
/// 每个分区独立管理展开状态，使用 StateProvider.family 按分区分别管理。
///
/// 使用方式：
/// ```dart
/// final expandedTaskIds = ref.watch(tasksSectionExpandedTaskIdProvider(TaskSection.today));
/// ```
final tasksSectionExpandedTaskIdProvider =
    StateProvider.family<Set<int>, TaskSection>((ref, section) => <int>{});

/// Provider for getting task level map for a specific section (虚拟字段)
///
/// 返回指定分区的 taskId -> level 的映射
/// 自动响应 taskSectionsProvider(section) 的变化
///
/// 使用方式：
/// ```dart
/// final levelMapAsync = ref.watch(tasksSectionTaskLevelMapProvider(TaskSection.today));
/// return levelMapAsync.when(
///   data: (levelMap) {
///     final taskLevel = levelMap[task.id] ?? 1;
///     // ...
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => SizedBox.shrink(),
/// );
/// ```
final tasksSectionTaskLevelMapProvider =
    FutureProvider.family<Map<int, int>, TaskSection>((ref, section) async {
  final tasksAsync = ref.watch(taskSectionsProvider(section));
  final tasks = await tasksAsync.requireValue;
  final taskRepository = ref.watch(taskRepositoryProvider);
  return _calculateTaskLevelMap(tasks, taskRepository);
});

/// Provider for getting task children map for a specific section (虚拟字段)
///
/// 返回指定分区的 taskId -> Set<子任务ID> 的映射
/// 自动响应 taskSectionsProvider(section) 的变化
///
/// 使用方式：
/// ```dart
/// final childrenMapAsync = ref.watch(tasksSectionTaskChildrenMapProvider(TaskSection.today));
/// return childrenMapAsync.when(
///   data: (childrenMap) {
///     final childTaskIds = childrenMap[task.id] ?? <int>{};
///     // ...
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => SizedBox.shrink(),
/// );
/// ```
final tasksSectionTaskChildrenMapProvider =
    FutureProvider.family<Map<int, Set<int>>, TaskSection>((ref, section) async {
  final tasksAsync = ref.watch(taskSectionsProvider(section));
  final tasks = await tasksAsync.requireValue;
  final taskRepository = ref.watch(taskRepositoryProvider);
  final childrenMap = <int, Set<int>>{};

  // 为每个任务查找所有子任务
  for (final task in tasks) {
    final children = await taskRepository.listChildren(task.id);
    final normalChildren = children
        .where((t) => !isProjectOrMilestone(t))
        .map((t) => t.id)
        .toSet();

    // 递归添加子任务的子任务
    final allChildren = <int>{...normalChildren};
    for (final childId in normalChildren) {
      final childChildren = await _getAllDescendants(childId, taskRepository);
      allChildren.addAll(childChildren);
    }

    childrenMap[task.id] = allChildren;
  }

  return childrenMap;
});

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
    return await ref
        .watch(taskServiceProvider)
        .listTagsByKind(TagKind.priority);
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
    return await ref
        .watch(taskServiceProvider)
        .listTagsByKind(TagKind.importance);
  } catch (error) {
    debugPrint('ImportanceTagOptionsProvider error: $error');
    return <Tag>[]; // 返回空列表而不是抛出错误
  }
});

final executionTagOptionsProvider = FutureProvider<List<Tag>>((ref) async {
  try {
    ref.watch(seedInitializerProvider);
    return await ref
        .watch(taskServiceProvider)
        .listTagsByKind(TagKind.execution);
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

  Future<void> updateFontScaleLevel(FontScaleLevel level) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _service.updateFontScaleLevel(level));
  }
}

final preferenceActionsNotifierProvider =
    AsyncNotifierProvider<PreferenceActionsNotifier, void>(() {
      return PreferenceActionsNotifier();
    });

/// 已完成任务分页状态
@immutable
class CompletedTasksPaginationState {
  const CompletedTasksPaginationState({
    this.tasks = const <Task>[],
    this.isLoading = false,
    this.hasMore = true,
    this.totalCount = 0,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool hasMore;
  final int totalCount;

  CompletedTasksPaginationState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? hasMore,
    int? totalCount,
  }) {
    return CompletedTasksPaginationState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// 已完成任务分页 Notifier
class CompletedTasksPaginationNotifier
    extends StateNotifier<CompletedTasksPaginationState> {
  CompletedTasksPaginationNotifier(this.ref)
      : super(const CompletedTasksPaginationState());

  final Ref ref;
  static const int _pageSize = 30;

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(completedTasksFilterProvider);
      
      final tasks = await _repository.listCompletedTasks(
        limit: _pageSize,
        offset: 0,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );
      final totalCount = await _repository.countCompletedTasks();

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        hasMore: tasks.length < totalCount,
        totalCount: totalCount,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load completed tasks: $error\n$stackTrace');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(completedTasksFilterProvider);
      
      final tasks = await _repository.listCompletedTasks(
        limit: _pageSize,
        offset: state.tasks.length,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );

      state = state.copyWith(
        tasks: [...state.tasks, ...tasks],
        isLoading: false,
        hasMore: tasks.length == _pageSize,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load more completed tasks: $error\n$stackTrace');
      state = state.copyWith(isLoading: false);
    }
  }
}

final completedTasksPaginationProvider = StateNotifierProvider<
    CompletedTasksPaginationNotifier, CompletedTasksPaginationState>((ref) {
  return CompletedTasksPaginationNotifier(ref);
});

/// 已归档任务分页状态
@immutable
class ArchivedTasksPaginationState {
  const ArchivedTasksPaginationState({
    this.tasks = const <Task>[],
    this.isLoading = false,
    this.hasMore = true,
    this.totalCount = 0,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool hasMore;
  final int totalCount;

  ArchivedTasksPaginationState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? hasMore,
    int? totalCount,
  }) {
    return ArchivedTasksPaginationState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// 已归档任务分页 Notifier
class ArchivedTasksPaginationNotifier
    extends StateNotifier<ArchivedTasksPaginationState> {
  ArchivedTasksPaginationNotifier(this.ref)
      : super(const ArchivedTasksPaginationState()) {
    debugPrint('[ArchivedPagination] Notifier created');
  }

  final Ref ref;
  static const int _pageSize = 30;

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (state.isLoading) {
      debugPrint('[ArchivedPagination] loadInitial: Already loading, skipping');
      return;
    }

    debugPrint('[ArchivedPagination] loadInitial: Starting load');
    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(archivedTasksFilterProvider);
      
      final tasks = await _repository.listArchivedTasks(
        limit: _pageSize,
        offset: 0,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );
      final totalCount = await _repository.countArchivedTasks();

      debugPrint(
        '[ArchivedPagination] loadInitial: Loaded ${tasks.length} tasks, totalCount=$totalCount',
      );

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        hasMore: tasks.length < totalCount,
        totalCount: totalCount,
      );

      debugPrint(
        '[ArchivedPagination] loadInitial: State updated - tasks=${state.tasks.length}, hasMore=${state.hasMore}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[ArchivedPagination] loadInitial: Failed - $error\n$stackTrace',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (state.isLoading) {
      debugPrint('[ArchivedPagination] loadMore: Already loading, skipping');
      return;
    }
    if (!state.hasMore) {
      debugPrint('[ArchivedPagination] loadMore: No more data, skipping');
      return;
    }

    debugPrint(
      '[ArchivedPagination] loadMore: Loading more, currentCount=${state.tasks.length}',
    );
    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(archivedTasksFilterProvider);
      
      final tasks = await _repository.listArchivedTasks(
        limit: _pageSize,
        offset: state.tasks.length,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );

      debugPrint(
        '[ArchivedPagination] loadMore: Loaded ${tasks.length} more tasks',
      );

      state = state.copyWith(
        tasks: [...state.tasks, ...tasks],
        isLoading: false,
        hasMore: tasks.length == _pageSize,
      );

      debugPrint(
        '[ArchivedPagination] loadMore: State updated - tasks=${state.tasks.length}, hasMore=${state.hasMore}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[ArchivedPagination] loadMore: Failed - $error\n$stackTrace',
      );
      state = state.copyWith(isLoading: false);
    }
  }
}

final archivedTasksPaginationProvider = StateNotifierProvider<
    ArchivedTasksPaginationNotifier, ArchivedTasksPaginationState>((ref) {
  return ArchivedTasksPaginationNotifier(ref);
});

/// 已删除任务分页状态
@immutable
class TrashedTasksPaginationState {
  const TrashedTasksPaginationState({
    this.tasks = const <Task>[],
    this.isLoading = false,
    this.hasMore = true,
    this.totalCount = 0,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool hasMore;
  final int totalCount;

  TrashedTasksPaginationState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? hasMore,
    int? totalCount,
  }) {
    return TrashedTasksPaginationState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// 已删除任务分页 Notifier
class TrashedTasksPaginationNotifier
    extends StateNotifier<TrashedTasksPaginationState> {
  TrashedTasksPaginationNotifier(this.ref)
      : super(const TrashedTasksPaginationState()) {
    debugPrint('[TrashedPagination] Notifier created');
  }

  final Ref ref;
  static const int _pageSize = 30;

  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (state.isLoading) {
      debugPrint('[TrashedPagination] loadInitial: Already loading, skipping');
      return;
    }

    debugPrint('[TrashedPagination] loadInitial: Starting load');
    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(trashedTasksFilterProvider);
      
      final tasks = await _repository.listTrashedTasks(
        limit: _pageSize,
        offset: 0,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );
      final totalCount = await _repository.countTrashedTasks();

      debugPrint(
        '[TrashedPagination] loadInitial: Loaded ${tasks.length} tasks, totalCount=$totalCount',
      );

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        hasMore: tasks.length < totalCount,
        totalCount: totalCount,
      );

      debugPrint(
        '[TrashedPagination] loadInitial: State updated - tasks=${state.tasks.length}, hasMore=${state.hasMore}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[TrashedPagination] loadInitial: Failed - $error\n$stackTrace',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (state.isLoading) {
      debugPrint('[TrashedPagination] loadMore: Already loading, skipping');
      return;
    }
    if (!state.hasMore) {
      debugPrint('[TrashedPagination] loadMore: No more data, skipping');
      return;
    }

    debugPrint(
      '[TrashedPagination] loadMore: Loading more, currentCount=${state.tasks.length}',
    );
    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(trashedTasksFilterProvider);
      
      final tasks = await _repository.listTrashedTasks(
        limit: _pageSize,
        offset: state.tasks.length,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );

      debugPrint(
        '[TrashedPagination] loadMore: Loaded ${tasks.length} more tasks',
      );

      state = state.copyWith(
        tasks: [...state.tasks, ...tasks],
        isLoading: false,
        hasMore: tasks.length == _pageSize,
      );

      debugPrint(
        '[TrashedPagination] loadMore: State updated - tasks=${state.tasks.length}, hasMore=${state.hasMore}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[TrashedPagination] loadMore: Failed - $error\n$stackTrace',
      );
      state = state.copyWith(isLoading: false);
    }
  }
}

final trashedTasksPaginationProvider = StateNotifierProvider<
    TrashedTasksPaginationNotifier, TrashedTasksPaginationState>((ref) {
  return TrashedTasksPaginationNotifier(ref);
});

