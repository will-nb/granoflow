import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
import '../../presentation/tasks/utils/sort_index_calculator.dart';
import '../constants/task_constants.dart';
import 'metric_orchestrator.dart';
import 'sort_index_service.dart';
import 'task_hierarchy_service.dart';

/// 任务提升服务
/// 处理子任务提升为独立任务的操作
class TaskPromotionService {
  TaskPromotionService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    SortIndexService? sortIndexService,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _sortIndex = sortIndexService;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final SortIndexService? _sortIndex;

  /// 处理子任务向左拖拽升级为根任务
  ///
  /// 当子任务向左拖拽超过指定阈值（30px）且垂直位移较小时，
  /// 将其提升为独立任务，排序在原父任务/祖任务之后。
  ///
  /// [taskId] 被拖拽的任务 ID
  /// [taskHierarchyService] 任务层级服务，用于执行 moveToParent 操作
  /// [horizontalOffset] 水平位移（负值表示向左）
  /// [verticalOffset] 垂直位移
  /// [leftDragThreshold] 向左拖拽的阈值（默认 -30.0）
  /// [verticalThreshold] 垂直位移的最大允许值（默认 50.0）
  ///
  /// 返回 true 如果成功执行了提升操作，false 如果条件不满足或操作失败
  Future<bool> handlePromoteToIndependent(
    int taskId,
    TaskHierarchyService taskHierarchyService, {
    required double? horizontalOffset,
    required double? verticalOffset,
    double leftDragThreshold = -30.0,
    double verticalThreshold = 50.0,
  }) async {
    // 检查条件：水平位移必须小于阈值，垂直位移必须小于阈值
    if (horizontalOffset == null || verticalOffset == null) {
      return false;
    }

    if (horizontalOffset >= leftDragThreshold) {
      // 未达到向左拖拽阈值
      return false;
    }

    if (verticalOffset.abs() >= verticalThreshold) {
      // 垂直位移过大，不是向左拖拽升级动作
      return false;
    }

    // 获取任务信息
    final task = await _tasks.findById(taskId);
    if (task == null || task.parentId == null) {
      // 任务不存在或不是子任务
      return false;
    }

    // 使用复用的异步方法计算任务的层级（level），直接通过 repository 查询
    final taskDepth = await calculateHierarchyDepth(task, _tasks);
    final taskLevel = taskDepth + 1; // level 1/2/3

    if (taskLevel < 2) {
      // 已经是根任务（level 1），不需要升级
      return false;
    }

    int? targetParentId;
    Task? referenceTask; // 用于计算 sortIndex 的参考任务

    if (taskLevel == 2) {
      // 2级任务：升级为根任务（level 1）
      targetParentId = null;
      // 找到父任务（根任务）作为参考
      final parent = await _tasks.findById(task.parentId!);
      if (parent == null) {
        return false;
      }
      referenceTask = parent;
    } else if (taskLevel == 3) {
      // 3级任务：升级为2级任务，成为其祖父任务的子任务
      final ancestors = await buildAncestorChain(taskId, _tasks);
      if (ancestors.isEmpty) {
        // 无法找到祖先，应该不会发生，但安全起见返回 false
        return false;
      }
      // ancestors 列表的顺序是：从最近的父任务到最远的祖先（已反转）
      // 对于 level 3 任务：ancestors[0] 是父任务（level 2），ancestors[ancestors.length - 1] 是祖父任务（level 1/根任务）
      // 我们需要祖父任务作为新的父任务
      if (ancestors.length < 2) {
        // 祖先链不足，无法确定祖父任务
        return false;
      }
      final grandparent = ancestors[ancestors.length - 1]; // 最远的祖先（根任务）
      targetParentId = grandparent.id;
      referenceTask = grandparent;
    } else {
      // 不支持超过3级的任务（理论上不应该发生）
      return false;
    }

    // referenceTask 在这里肯定不为 null（因为前面的分支都有返回值或赋值）

    // 计算新的 sortIndex：排在参考任务之后
    final newSortIndex = SortIndexCalculator.insertAfter(
      referenceTask.sortIndex,
    );

    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: promoteToIndependent, taskId: $taskId, taskLevel: $taskLevel, targetParentId: $targetParentId, referenceTaskId: ${referenceTask.id}, newSortIndex: $newSortIndex, horizontalOffset: $horizontalOffset, verticalOffset: $verticalOffset}',
      );
    }

    try {
      // 执行升级操作
      await taskHierarchyService.moveToParent(
        taskId: taskId,
        parentId: targetParentId,
        sortIndex: newSortIndex,
        clearParent: targetParentId == null,
      );

      // 批量重排所有 inbox 任务的 sortIndex
      final sortIndex = _sortIndex;
      if (sortIndex != null) {
        final allInboxTasks = await _tasks.watchInbox().first;
        await sortIndex.reorderTasksForInbox(tasks: allInboxTasks);
      }

      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: promoteToIndependent:success, taskId: $taskId}',
        );
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: promoteToIndependent:error, taskId: $taskId, error: $e}',
        );
        debugPrint('$stackTrace');
      }
      return false;
    }
  }

  /// 将子任务提升为根任务（用于滑动动作）
  ///
  /// 无论子任务是 level 2 还是 level 3，都直接设置为根任务（parentId = null）
  /// 这是滑动动作专用的方法，与拖拽的 handlePromoteToIndependent 不同
  ///
  /// [taskId] 要提升的任务 ID
  /// [taskLevel] 任务的层级（可选），如果提供则避免重新计算
  ///
  /// 返回 true 如果成功执行了提升操作，false 如果条件不满足或操作失败
  Future<bool> promoteSubtaskToRoot(int taskId, {int? taskLevel}) async {
    // 获取任务信息
    final task = await _tasks.findById(taskId);
    if (task == null || task.parentId == null) {
      // 任务不存在或已经是根任务
      if (kDebugMode) {
        debugPrint(
          '[TaskPromotionService.promoteSubtaskToRoot] 失败: taskId=$taskId, 任务不存在或已是根任务',
        );
      }
      return false;
    }

    // 如果传入了 taskLevel，使用它；否则需要计算
    int actualLevel;
    if (taskLevel != null && taskLevel > 1) {
      actualLevel = taskLevel;
    } else {
      // 如果没有传入，计算 level（性能较差，不推荐）
      final taskDepth = await calculateHierarchyDepth(task, _tasks);
      actualLevel = taskDepth + 1;
    }

    if (actualLevel < 2) {
      // 已经是根任务
      return false;
    }

    // 直接设置为根任务：parentId = null
    // 获取当前 inbox 任务列表，计算合适的 sortIndex
    try {
      final inboxTasks = await _tasks.watchInbox().first;
      final rootTasks = inboxTasks
          .where((t) => t.parentId == null && t.id != taskId)
          .toList();

      // 使用统一的排序函数排序根任务
      SortIndexService.sortTasksForInbox(rootTasks);

      // 计算新的 sortIndex：插入到第一个根任务之前
      final sortIndexService = _sortIndex;
      double newSortIndex;
      if (rootTasks.isEmpty) {
        // 如果没有其他根任务，使用默认值
        newSortIndex = TaskConstants.DEFAULT_SORT_INDEX;
      } else {
        // 插入到第一个根任务之前
        final firstRoot = rootTasks.first;
        if (sortIndexService != null) {
          // 检查是否需要先规范化区域
          final dragged = await _tasks.findById(taskId);
          if (dragged != null &&
              (firstRoot.sortIndex - dragged.sortIndex).abs() < 2.0) {
            // 间隙太小，先规范化区域
            await sortIndexService.normalizeSection(section: TaskSection.later);
            // 重新获取第一个根任务（可能 sortIndex 已变化）
            final updatedInboxTasks = await _tasks.watchInbox().first;
            final updatedRootTasks = updatedInboxTasks
                .where((t) => t.parentId == null && t.id != taskId)
                .toList();
            SortIndexService.sortTasksForInbox(updatedRootTasks);
            if (updatedRootTasks.isNotEmpty) {
              newSortIndex = (updatedRootTasks.first.sortIndex - 1024)
                  .toDouble();
            } else {
              newSortIndex = TaskConstants.DEFAULT_SORT_INDEX;
            }
          } else {
            // 间隙足够，直接计算
            newSortIndex = (firstRoot.sortIndex - 1024).toDouble();
          }
        } else {
          // 退化实现：直接计算
          newSortIndex = (firstRoot.sortIndex - 1024).toDouble();
        }
      }

      // 一次性更新：清空 parentId 并设置 sortIndex
      await _tasks.updateTask(
        taskId,
        TaskUpdate(
          clearParent: true, // 清空 parentId，变为根任务
          sortIndex: newSortIndex,
        ),
      );

      // 批量重排所有 inbox 任务的 sortIndex（确保有足够的间隙）
      if (sortIndexService != null) {
        final allInboxTasks = await _tasks.watchInbox().first;
        await sortIndexService.reorderTasksForInbox(tasks: allInboxTasks);
      }

      if (kDebugMode) {
        debugPrint(
          '[TaskPromotionService.promoteSubtaskToRoot] 成功: taskId=$taskId, level=$actualLevel -> 1',
        );
      }

      await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[TaskPromotionService.promoteSubtaskToRoot] 错误: taskId=$taskId, error=$e',
        );
        debugPrint('$stackTrace');
      }
      return false;
    }
  }
}

