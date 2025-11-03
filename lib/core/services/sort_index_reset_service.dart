import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../constants/task_constants.dart';

class SortIndexResetService {
  SortIndexResetService({
    required TaskRepository taskRepository,
  }) : _tasks = taskRepository;

  final TaskRepository _tasks;

  /// 重置所有任务的 sortIndex 为默认值
  Future<void> resetAllSortIndexes() async {
    try {
      // 获取所有任务
      final allTasks = await _tasks.listAll();
      
      for (final task in allTasks) {
        if (task.sortIndex != TaskConstants.DEFAULT_SORT_INDEX) {
          await _tasks.updateTask(
            task.id,
            TaskUpdate(sortIndex: TaskConstants.DEFAULT_SORT_INDEX),
          );
        }
      }
    } catch (e) {
      debugPrint('SortIndexResetService: 重置失败: $e');
      rethrow;
    }
  }
}
