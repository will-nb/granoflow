import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task.dart';
import '../services/task_service.dart';
import 'service_providers.dart';


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

