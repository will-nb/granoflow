import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../constants/task_constants.dart';

class SortIndexResetService {
  SortIndexResetService({
    required TaskRepository taskRepository,
  }) : _tasks = taskRepository;

  final TaskRepository _tasks;

  /// 重置所有任务的 sortIndex 为初始值
  /// 
  /// 根据任务状态和创建时间生成不同的初始 sortIndex：
  /// - 已完成任务（completedActive）：从 -100000.0 开始，步长 1000.0
  /// - 其他状态任务：从 0.0 开始，步长 1000.0
  /// - 在同一组内，按 createdAt 升序排序，保持相对顺序
  Future<void> resetAllSortIndexes() async {
    try {
      // 获取所有任务
      final allTasks = await _tasks.listAll();
      
      if (allTasks.isEmpty) {
        debugPrint('SortIndexResetService: 没有任务需要重置');
        return;
      }

      // 按状态分组
      final completedTasks = allTasks
          .where((t) => t.status == TaskStatus.completedActive)
          .toList();
      final otherTasks = allTasks
          .where((t) => t.status != TaskStatus.completedActive)
          .toList();

      debugPrint(
        'SortIndexResetService: 重置 sortIndexes - '
        '总任务数: ${allTasks.length}, '
        '已完成: ${completedTasks.length}, '
        '其他: ${otherTasks.length}',
      );

      // 在每个组内按 createdAt 升序排序（保持创建顺序）
      completedTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      otherTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 使用与 TaskStatusToggleHelper 相同的常量值确保兼容性
      const double step = 1000.0;
      const double completedStart = -100000.0;
      const double otherStart = 0.0;

      final updates = <String, TaskUpdate>{};

      // completedActive 组：从 -100000 开始
      for (var i = 0; i < completedTasks.length; i++) {
        final newSortIndex = completedStart + i * step;
        updates[completedTasks[i].id] = TaskUpdate(
          sortIndex: newSortIndex,
        );
        debugPrint(
          'SortIndexResetService: 已完成任务 ${completedTasks[i].id}: '
          'old sortIndex=${completedTasks[i].sortIndex}, new sortIndex=$newSortIndex',
        );
      }

      // 其他组：从 0 开始
      for (var i = 0; i < otherTasks.length; i++) {
        final newSortIndex = otherStart + i * step;
        updates[otherTasks[i].id] = TaskUpdate(
          sortIndex: newSortIndex,
        );
        debugPrint(
          'SortIndexResetService: 其他任务 ${otherTasks[i].id}: '
          'old sortIndex=${otherTasks[i].sortIndex}, new sortIndex=$newSortIndex',
        );
      }

      // 批量更新
      if (updates.isNotEmpty) {
        debugPrint(
          'SortIndexResetService: 批量更新 ${updates.length} 个任务的 sortIndex',
        );
        await _tasks.batchUpdate(updates);
        debugPrint('SortIndexResetService: 批量更新完成');
      } else {
        debugPrint('SortIndexResetService: 无需更新');
      }
    } catch (e) {
      debugPrint('SortIndexResetService: 重置失败: $e');
      rethrow;
    }
  }
}
