import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/task_constants.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/task.dart';
import '../../tasks/utils/sort_index_calculator.dart';
import '../drag/task_drag_intent_target.dart';
import 'task_list_config.dart';

/// 任务列表插入拖拽处理工具类
///
/// 职责：统一的插入拖拽处理逻辑
/// - 处理插入拖拽的 drop 操作
/// - 通过 TaskListConfig 处理 Inbox 和 Tasks 的差异
///   - Inbox：无 section，使用 reorderTasksForInbox
///   - Tasks：有 section，使用 reorderTasksForSameDate，处理跨区域拖拽和 dueDate
class TaskListInsertionHandler {
  TaskListInsertionHandler._();

  /// 统一处理插入目标的 drop 逻辑
  ///
  /// [draggedTask] 被拖拽的任务
  /// [beforeTask] 插入位置之前的任务（null 表示插入到开头）
  /// [afterTask] 插入位置之后的任务（null 表示插入到结尾）
  /// [targetType] 插入目标类型（first, between, last）
  /// [config] 任务列表配置（用于处理 Inbox 和 Tasks 的差异）
  /// [ref] WidgetRef
  static Future<TaskDragIntentResult> handleInsertionDrop(
    Task draggedTask,
    Task? beforeTask,
    Task? afterTask,
    String targetType,
    TaskListConfig config,
    WidgetRef ref,
  ) async {
    // 层级功能已移除，不再有子任务升级
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: _handleInsertionDrop:start, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, targetType: $targetType, beforeTask: ${beforeTask?.id}, afterTask: ${afterTask?.id}, beforeSortIndex: ${beforeTask?.sortIndex}, afterSortIndex: ${afterTask?.sortIndex}}',
      );
    }
    try {
      final taskHierarchyService = await ref.read(taskHierarchyServiceProvider.future);

      // 层级功能已移除，不再需要 parentId
      double newSortIndex;

      // 通过 config.handleDueDate 处理 dueDate（Inbox 和 Tasks 的差异）
      final targetDueDate = config.handleDueDate(
        section: config.section,
        beforeTask: beforeTask,
        afterTask: afterTask,
        draggedTask: draggedTask,
      );

      if (targetType == 'first') {
        // 顶部插入目标
        newSortIndex = SortIndexCalculator.insertAtFirst(beforeTask?.sortIndex);
      } else if (targetType == 'last') {
        // 底部插入目标：最后一个任务作为 beforeTask（afterTask = null）
        newSortIndex = SortIndexCalculator.insertAtLast(beforeTask?.sortIndex);
      } else {
        // 中间插入目标
        if (beforeTask != null && afterTask != null) {
          // 两个任务都存在：插入到它们之间
          newSortIndex = SortIndexCalculator.insertBetween(
            beforeTask.sortIndex,
            afterTask.sortIndex,
          );
        } else if (beforeTask != null) {
          // 只有 beforeTask 存在：插入到 beforeTask 之后
          newSortIndex = SortIndexCalculator.insertAfter(beforeTask.sortIndex);
        } else {
          // 两个任务都不存在：使用默认值（这种情况理论上不应该发生）
          newSortIndex = TaskConstants.DEFAULT_SORT_INDEX;
        }
      }

      // 统一使用 moveToParent 处理
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: call:moveToParent, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, sortIndex: $newSortIndex, dueAt: $targetDueDate}',
        );
      }

      // 通过 config.handleMilestoneId 处理 milestoneId（用于跨里程碑拖拽）
      final targetMilestoneId = config.handleMilestoneId(
        beforeTask: beforeTask,
        afterTask: afterTask,
        draggedTask: draggedTask,
      );

      await taskHierarchyService.moveToParent(
        taskId: draggedTask.id,
        parentId: null, // 层级功能已移除
        sortIndex: newSortIndex,
        dueDate: targetDueDate, // Tasks 页面会传入 targetDueDate，Inbox 页面传入 null
        clearParent: false, // 层级功能已移除
      );

      // 如果 milestoneId 发生变化，更新任务的 milestoneId
      if (targetMilestoneId != null && targetMilestoneId != draggedTask.milestoneId) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: milestoneId:update, page: ${config.pageName}, src: ${draggedTask.id}, oldMilestoneId: ${draggedTask.milestoneId}, newMilestoneId: $targetMilestoneId}',
          );
        }
        try {
          final taskService = await ref.read(taskServiceProvider.future);
          await taskService.updateDetails(
            taskId: draggedTask.id,
            payload: TaskUpdate(milestoneId: targetMilestoneId),
          );
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: milestoneId:update:failed, page: ${config.pageName}, src: ${draggedTask.id}, newMilestoneId: $targetMilestoneId, error: $e, stackTrace: $stackTrace}',
            );
          }
          // 继续执行重排序，不中断整个流程
        }
      }

      // 通过 config.reorderTasks 执行重排序（Inbox 和 Tasks 的差异）
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final allTasks = await taskRepository.listAll();
      await config.reorderTasks(
        ref: ref,
        allTasks: allTasks,
        targetDate: targetDueDate,
      );

      if (kDebugMode) {
        if (config.section != null) {
          debugPrint(
            '[DnD] {event: reorderTasksForSameDate:completed, page: ${config.pageName}, section: ${config.section?.name}, targetDate: $targetDueDate}',
          );
        } else {
          debugPrint(
            '[DnD] {event: reorderTasksForInbox:completed, page: ${config.pageName}}',
          );
        }
        debugPrint(
          '[DnD] {event: accept:success, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, sortIndex: $newSortIndex}',
        );
      }

      return TaskDragIntentResult.success(
        parentId: null, // 层级功能已移除
        sortIndex: newSortIndex,
        clearParent: false, // 层级功能已移除
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:error, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, error: $e, stackTrace: $stackTrace}',
        );
      }
      return const TaskDragIntentResult.blocked(
        blockReasonKey: 'taskMoveBlockedUnknown',
        blockLogTag: 'serviceError',
      );
    }
  }
}

