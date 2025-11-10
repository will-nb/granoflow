import 'package:flutter/foundation.dart';

import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
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

  Future<void> moveToParent({
    required String taskId,
    required String? parentId,
    required double sortIndex,
    DateTime? dueDate,
    bool clearParent = false,
  }) async {
    if (kDebugMode) {
      debugPrint('[DnD] {event: service:moveToParent:start, taskId: $taskId, parentId: $parentId, sortIndex: $sortIndex, dueAt: $dueDate, clearParent: $clearParent}');
    }
    final task = await _tasks.findById(taskId);
    if (task == null) return;
    
    // 验证锁定状态：被拖拽的任务是否被锁定
    if (!canMoveTask(task)) {
      if (kDebugMode) {
        debugPrint('[DnD] {event: service:block:sourceLocked, taskId: $taskId}');
      }
      throw StateError('Task is locked and cannot be moved.');
    }
    
    Task? parent;
    if (parentId != null) {
      parent = await _tasks.findById(parentId);
      if (parent == null) {
        if (kDebugMode) {
          debugPrint('[DnD] {event: service:error:parentNotFound, parentId: $parentId}');
        }
        throw StateError('Parent task $parentId not found.');
      }
      
      // 验证锁定状态与类型：目标父任务是否可以接受子任务
      if (!canAcceptChildren(parent)) {
        if (kDebugMode) {
          debugPrint('[DnD] {event: service:block:targetLocked, taskId: $taskId, parentId: $parentId}');
        }
        throw StateError('Parent task is locked; cannot add children.');
      }
      
      // 验证循环引用
      if (await hasCircularReference(task, parentId, _tasks)) {
        if (kDebugMode) {
          debugPrint('[DnD] {event: service:block:cycle, taskId: $taskId, parentId: $parentId}');
        }
        throw StateError('Cannot move task to its own descendant.');
      }
      
      // 验证层级深度限制（最多3级，不含里程碑和项目）
      // 采用父深度 + 被拖拽子树深度 的合并判断
    final parentDepth = await calculateHierarchyDepth(parent, _tasks);
    final draggedSubtreeDepth = await calculateSubtreeDepth(task, _tasks);
      if (kDebugMode) {
        debugPrint('[DnD] {event: service:depthCheck, taskId: $taskId, parentId: $parentId, parentDepth: $parentDepth, subtreeDepth: $draggedSubtreeDepth}');
      }
      if (parentDepth + draggedSubtreeDepth > 2) {
        if (kDebugMode) {
          debugPrint('[DnD] {event: service:block:depth, taskId: $taskId, parentId: $parentId}');
        }
        throw StateError('Task hierarchy depth limit (3 levels) exceeded.');
      }
    }
    
    if (kDebugMode) {
      debugPrint('[DnD] {event: service:repo:updateTask, taskId: $taskId, parentId: $parentId, sortIndex: $sortIndex}');
    }
    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        parentId: parentId,
        sortIndex: sortIndex,
        clearParent: parentId == null || clearParent ? true : null,
        dueAt: dueDate,
      ),
    );
    if (kDebugMode) {
      final saved = await _tasks.findById(taskId);
      debugPrint('[DnD] {event: service:done, taskId: $taskId, parentId: ${saved?.parentId}, sortIndex: ${saved?.sortIndex}, dueAt: ${saved?.dueAt}}');
    }
  }
  
  /// 计算将任务移动到父任务下的合适 sortIndex
  /// 
  /// 如果父任务已有子任务，插入到第一个子任务之前；
  /// 否则使用默认值
  Future<double> calculateSortIndexForNewChild(String parentId) async {
    final children = await _tasks.listChildren(parentId);
    
    if (children.isEmpty) {
      return TaskConstants.DEFAULT_SORT_INDEX;
    }
    
    // 插入到第一个子任务之前
    final firstChildSortIndex = children.first.sortIndex;
    final newSortIndex = (firstChildSortIndex - 1024.0).clamp(
      TaskConstants.DEFAULT_SORT_INDEX - 10000.0,
      TaskConstants.DEFAULT_SORT_INDEX,
    );
    
    return newSortIndex;
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
