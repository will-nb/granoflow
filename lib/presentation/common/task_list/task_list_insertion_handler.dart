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
    // 检查是否是子任务升级为根任务的情况
    final isSubtaskPromotion = draggedTask.parentId != null;
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: _handleInsertionDrop:start, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, isSubtaskPromotion: $isSubtaskPromotion, originalParentId: ${draggedTask.parentId}, targetType: $targetType, beforeTask: ${beforeTask?.id}, afterTask: ${afterTask?.id}, beforeSortIndex: ${beforeTask?.sortIndex}, afterSortIndex: ${afterTask?.sortIndex}}',
      );
    }
    try {
      final taskHierarchyService = await ref.read(taskHierarchyServiceProvider.future);

      // 确定上方任务的 parentId
        String? aboveTaskParentId;
      double newSortIndex;

      // 通过 config.handleDueDate 处理 dueDate（Inbox 和 Tasks 的差异）
      final targetDueDate = config.handleDueDate(
        section: config.section,
        beforeTask: beforeTask,
        afterTask: afterTask,
        draggedTask: draggedTask,
      );

      if (targetType == 'first') {
        // 顶部插入目标：成为根项目（parentId = null）
        aboveTaskParentId = null;
        newSortIndex = SortIndexCalculator.insertAtFirst(beforeTask?.sortIndex);
      } else if (targetType == 'last') {
        // 底部插入目标：最后一个任务作为 beforeTask（afterTask = null）
        // 成为最后一个任务的兄弟
        aboveTaskParentId = beforeTask?.parentId;
        newSortIndex = SortIndexCalculator.insertAtLast(beforeTask?.sortIndex);
      } else {
        // 中间插入目标：成为 beforeTask 的兄弟
        aboveTaskParentId = beforeTask?.parentId;
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
        if (isSubtaskPromotion && aboveTaskParentId == null) {
          debugPrint(
            '[DnD] {event: subtaskPromotion, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, originalParentId: ${draggedTask.parentId}, newParentId: null (root), sortIndex: $newSortIndex, dueAt: $targetDueDate}',
          );
        }
        debugPrint(
          '[DnD] {event: call:moveToParent, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, parentId: $aboveTaskParentId, sortIndex: $newSortIndex, dueAt: $targetDueDate}',
        );
      }

      await taskHierarchyService.moveToParent(
        taskId: draggedTask.id,
        parentId: aboveTaskParentId,
        sortIndex: newSortIndex,
        dueDate: targetDueDate, // Tasks 页面会传入 targetDueDate，Inbox 页面传入 null
        clearParent: aboveTaskParentId == null, // 只有成为根项目时才 clearParent
      );

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
          '[DnD] {event: accept:success, page: ${config.pageName}, section: ${config.section?.name ?? "null"}, src: ${draggedTask.id}, parentId: $aboveTaskParentId, sortIndex: $newSortIndex}',
        );
      }

      return TaskDragIntentResult.success(
        parentId: aboveTaskParentId,
        sortIndex: newSortIndex,
        clearParent: aboveTaskParentId == null,
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

