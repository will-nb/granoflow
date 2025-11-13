import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task.dart';
import '../services/task_service.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// Provider: 获取已完成任务的所有子任务（包括 trashed 状态）
/// 用于在已完成页面展开任务时显示子任务
final completedTaskChildrenProvider =
    FutureProvider.family<List<Task>, String>((ref, parentId) async {
  final taskRepository = await ref.read(taskRepositoryProvider.future);
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
  final taskRepository = await ref.read(taskRepositoryProvider.future);
  final children = await taskRepository.listChildrenIncludingTrashed(parentId);
  // 只返回已归档状态的子任务
  return children
      .where((task) => task.status == TaskStatus.archived)
      .toList();
});

class TaskEditActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<TaskService> get _taskService async => await ref.read(taskServiceProvider.future);


  Future<void> editTitle({required String taskId, required String title}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final taskService = await _taskService;
      await taskService.updateDetails(
        taskId: taskId,
        payload: TaskUpdate(title: title),
      );
    });
  }

  Future<void> archive(String taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final taskService = await _taskService;
      return taskService.archive(taskId);
    });
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

