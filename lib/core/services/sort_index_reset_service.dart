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
    debugPrint('🔄 SortIndexResetService: 开始重置所有任务的 sortIndex');
    
    try {
      // 获取所有任务
      final allTasks = await _tasks.listAll();
      debugPrint('📋 找到 ${allTasks.length} 个任务需要重置');
      
      int resetCount = 0;
      for (final task in allTasks) {
        if (task.sortIndex != TaskConstants.DEFAULT_SORT_INDEX) {
          await _tasks.updateTask(
            task.id,
            TaskUpdate(sortIndex: TaskConstants.DEFAULT_SORT_INDEX),
          );
          resetCount++;
          debugPrint('✅ 重置任务 ${task.id}(${task.title}) 的 sortIndex: ${task.sortIndex} -> ${TaskConstants.DEFAULT_SORT_INDEX}');
        }
      }
      
      debugPrint('🎉 SortIndexResetService: 重置完成，共重置了 $resetCount 个任务');
    } catch (e) {
      debugPrint('❌ SortIndexResetService: 重置失败: $e');
      rethrow;
    }
  }
}
