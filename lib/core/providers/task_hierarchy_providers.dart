import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
import 'repository_providers.dart';
import 'service_providers.dart';
import 'task_query_providers.dart';

/// 辅助函数：计算任务列表的 level 映射
///
/// [tasks] 任务列表
/// [repository] 任务仓库
/// 返回 taskId -> level 的映射（level = depth + 1）
Future<Map<String, int>> _calculateTaskLevelMap(
  List<Task> tasks,
  TaskRepository repository,
) async {
  final levelMap = <String, int>{};

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
final inboxTaskLevelMapProvider = FutureProvider<Map<String, int>>((ref) async {
  final tasksAsync = ref.watch(inboxTasksProvider);
  final tasks = await tasksAsync.requireValue;
  final taskRepository = await ref.read(taskRepositoryProvider.future);
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
///   loading: () => const AsyncLoading<Map<String, int>>(),
///   error: (_, __) => const AsyncError<Map<String, int>>(null, StackTrace.empty),
/// );
/// ```
final taskLevelMapProvider = FutureProvider.family<Map<String, int>, List<Task>>((
  ref,
  tasks,
) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  return _calculateTaskLevelMap(tasks, taskRepository);
});

/// 辅助函数：递归获取所有后代任务 ID
Future<Set<String>> _getAllDescendants(
  String taskId,
  TaskRepository repository,
) async {
  final result = <String>{};
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
///     final childTaskIds = childrenMap[task.id] ?? <String>{};
///     // ...
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => SizedBox.shrink(),
/// );
/// ```
final inboxTaskChildrenMapProvider = FutureProvider<Map<String, Set<String>>>((
  ref,
) async {
  final tasksAsync = ref.watch(inboxTasksProvider);
  final tasks = await tasksAsync.requireValue;
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final childrenMap = <String, Set<String>>{};

  // 为每个任务查找所有子任务
  for (final task in tasks) {
    final children = await taskRepository.listChildren(task.id);
      final normalChildren = children
          .where((t) => !isProjectOrMilestone(t))
          .map((t) => t.id)
          .toSet();

    // 递归添加子任务的子任务
      final allChildren = <String>{...normalChildren};
    for (final childId in normalChildren) {
      final childChildren = await _getAllDescendants(childId, taskRepository);
      allChildren.addAll(childChildren);
    }

    childrenMap[task.id] = allChildren;
  }

  return childrenMap;
});

/// Provider for getting the parent task of a task (could be project or milestone)
final taskParentProvider = FutureProvider.family<Task?, String>((
  ref,
  taskId,
) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final task = await taskRepository.findById(taskId);
  if (task?.parentId == null) return null;
  return taskRepository.findById(task!.parentId!);
});

/// Provider for getting the complete hierarchy of a task (project and milestone if applicable)
class TaskProjectHierarchy {
  const TaskProjectHierarchy({required this.project, this.milestone});

  final Project project;
  final Milestone? milestone;

  bool get hasMilestone => milestone != null;
}

final taskProjectHierarchyProvider =
    StreamProvider.family<TaskProjectHierarchy?, String>((ref, taskId) async* {
  // 使用 watchTaskById 监听任务变化，这样当任务的项目/里程碑字段更新时，会自动触发
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final taskStream = taskRepository.watchTaskById(taskId);
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

    final projectServiceAsync = ref.watch(projectServiceProvider);
    final projectService = await projectServiceAsync.requireValue;
    final project = await projectService.findById(projectId);
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

final taskTreeProvider = StreamProvider.family<TaskTreeNode, String>((
  ref,
  rootId,
) async* {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  yield* taskRepository.watchTaskTree(rootId);
});

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
    FutureProvider.family<Map<String, int>, TaskSection>((ref, section) async {
  final tasksAsync = ref.watch(taskSectionsProvider(section));
  final tasks = await tasksAsync.requireValue;
  final taskRepository = await ref.read(taskRepositoryProvider.future);
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
    FutureProvider.family<Map<String, Set<String>>, TaskSection>((ref, section) async {
  final tasksAsync = ref.watch(taskSectionsProvider(section));
  final tasks = await tasksAsync.requireValue;
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final childrenMap = <String, Set<String>>{};

  // 为每个任务查找所有子任务
  for (final task in tasks) {
    final children = await taskRepository.listChildren(task.id);
      final normalChildren = children
          .where((t) => !isProjectOrMilestone(t))
          .map((t) => t.id)
          .toSet();

    // 递归添加子任务的子任务
      final allChildren = <String>{...normalChildren};
    for (final childId in normalChildren) {
      final childChildren = await _getAllDescendants(childId, taskRepository);
      allChildren.addAll(childChildren);
    }

    childrenMap[task.id] = allChildren;
  }

  return childrenMap;
});

