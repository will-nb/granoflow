import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task.dart';
import '../constants/task_constants.dart';
import '../services/task_hierarchy_service.dart';
import '../services/task_service.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// Provider: 获取已完成任务的所有子任务（包括 trashed 状态）
/// 用于在已完成页面展开任务时显示子任务
final completedTaskChildrenProvider =
    FutureProvider.family<List<Task>, String>((ref, parentId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  final children = await taskRepository.listChildrenIncludingTrashed(parentId);
  // 只返回已完成状态的子任务
  return children
      .where((task) => task.status == TaskStatus.completedActive)
      .toList();
});

/// Provider: 获取已归档任务的所有子任务（包括 trashed 状态）
/// 用于在已归档页面展开任务时显示子任务
final archivedTaskChildrenProvider =
    FutureProvider.family<List<Task>, String>((ref, parentId) async {
  final taskRepository = ref.read(taskRepositoryProvider);
  final children = await taskRepository.listChildrenIncludingTrashed(parentId);
  // 只返回已归档状态的子任务
  return children
      .where((task) => task.status == TaskStatus.archived)
      .toList();
});

class TaskEditActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  TaskService get _taskService => ref.read(taskServiceProvider);
  TaskHierarchyService get _hierarchyService =>
      ref.read(taskHierarchyServiceProvider);

  Future<void> addSubtask({
    required String parentId,
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

  Future<void> editTitle({required String taskId, required String title}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _taskService.updateDetails(
        taskId: taskId,
        payload: TaskUpdate(title: title),
      );
    });
  }

  Future<void> archive(String taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _taskService.archive(taskId));
  }
}

final taskEditActionsNotifierProvider =
    AsyncNotifierProvider<TaskEditActionsNotifier, void>(() {
      return TaskEditActionsNotifier();
    });

/// 当前正在编辑的任务ID
/// null 表示没有任务在编辑状态
/// 用于确保同一时刻只有一个任务可以处于编辑状态
final currentEditingTaskIdProvider = StateProvider<String?>((ref) => null);

