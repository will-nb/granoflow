import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../constants/task_constants.dart';
import 'metric_orchestrator.dart';

class TaskHierarchyService {
  TaskHierarchyService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;

  Future<void> reorderWithinSection({
    required String taskId,
    required double targetIndex,
    required TaskSection section,
  }) async {
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: targetIndex,
    );
  }

  /// 层级功能已移除，moveToParent 简化为只更新 sortIndex 和 dueAt
  Future<void> moveToParent({
    required String taskId,
    required String? parentId, // 不再使用，保留以保持 API 兼容
    required double sortIndex,
    DateTime? dueDate,
    bool clearParent = false, // 不再使用，保留以保持 API 兼容
  }) async {
    if (kDebugMode) {
      debugPrint('[DnD] {event: service:moveToParent:start, taskId: $taskId, sortIndex: $sortIndex, dueAt: $dueDate}');
    }
    final task = await _tasks.findById(taskId);
    if (task == null) return;
    
    // 验证锁定状态：被拖拽的任务是否被锁定
    if (!task.canEditStructure) {
      if (kDebugMode) {
        debugPrint('[DnD] {event: service:block:sourceLocked, taskId: $taskId}');
      }
      throw StateError('Task is locked and cannot be moved.');
    }
    
    // 层级功能已移除，只更新 sortIndex 和 dueAt
    if (kDebugMode) {
      debugPrint('[DnD] {event: service:repo:updateTask, taskId: $taskId, sortIndex: $sortIndex}');
    }
    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        sortIndex: sortIndex,
        dueAt: dueDate,
      ),
    );
    if (kDebugMode) {
      final saved = await _tasks.findById(taskId);
      debugPrint('[DnD] {event: service:done, taskId: $taskId, sortIndex: ${saved?.sortIndex}, dueAt: ${saved?.dueAt}}');
    }
  }
  
  /// 层级功能已移除，不再需要计算子任务的 sortIndex
  Future<double> calculateSortIndexForNewChild(String parentId) async {
    // 层级功能已移除，返回默认值
    return TaskConstants.DEFAULT_SORT_INDEX;
  }

  Future<void> moveAcrossSections({
    required String taskId,
    required TaskSection section,
    required double sortIndex,
    required DateTime dueDateLocal,
  }) async {
    final normalized = DateTime(
      dueDateLocal.year,
      dueDateLocal.month,
      dueDateLocal.day,
      23,
      59,
      59,
    );
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: sortIndex,
      dueAt: normalized,
    );
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }
}
