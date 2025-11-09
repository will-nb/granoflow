import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/task.dart';
import '../../tasks/utils/tree_flattening_utils.dart';
import '../../tasks/utils/hierarchy_utils.dart';
import '../drag/task_drag_intent_target.dart';
import '../drag/standard_drag_target.dart';
import 'task_list_config.dart';
import 'task_list_insertion_handler.dart';
import 'task_list_expansion_detector.dart';

/// 插入目标构建工具类
///
/// 职责：构建插入目标 Widget（顶部、中间、底部）
/// - 构建顶部插入目标
/// - 构建中间插入目标
/// - 构建底部插入目标
/// - 处理插入目标的拖拽逻辑
class TaskListInsertionTargetBuilder {
  TaskListInsertionTargetBuilder._();

  /// 构建顶部插入目标
  static Widget buildTopInsertionTarget({
    required List<FlattenedTaskNode> flattenedTasks,
    required List<Task> filteredTasks,
    required TaskListConfig config,
    required dynamic dragState,
    required dynamic dragNotifier,
    required WidgetRef ref,
  }) {
    return TaskDragIntentTarget.insertion(
      key: ValueKey('${config.pageName.toLowerCase()}-insertion-first'),
        meta: TaskDragIntentMeta(
          page: config.pageName,
          targetType: 'insertionFirst',
          targetId: 'first',
          targetTaskId: flattenedTasks.isNotEmpty ? flattenedTasks[0].task.id : null,
          section: config.section?.name,
        ),
      insertionType: InsertionType.first,
      showWhenIdle: false,
      canAccept: (draggedTask, _) {
        final movable = canMoveTask(draggedTask);
        if (flattenedTasks.isEmpty) return false;
        return movable && draggedTask.id != flattenedTasks[0].task.id;
      },
      onPerform: (draggedTask, ref, context, l10n) async {
        final beforeTask = flattenedTasks.isNotEmpty ? flattenedTasks[0].task : null;
        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          null, // beforeTask 为 null（顶部插入）
          beforeTask, // afterTask 是第一个任务
          'first',
          config,
          ref,
        );
        dragNotifier.endDrag();
        return result;
      },
      onHover: (isHovering, _) async {
        if (isHovering) {
          _handleExpansionAreaDetection(
            dragState: dragState,
            dragNotifier: dragNotifier,
            flattenedTasks: flattenedTasks,
            filteredTasks: filteredTasks,
            hoveredTaskId: null,
            hoveredInsertionIndex: 0,
          );
          _updateInsertionHover(dragNotifier, 0, config.section);
        }
      },
    );
  }

  /// 构建中间插入目标
  static Widget buildMiddleInsertionTarget({
    required int insertionIndex,
    required Task beforeTask,
    required Task afterTask,
    required List<FlattenedTaskNode> flattenedTasks,
    required List<Task> filteredTasks,
    required TaskListConfig config,
    required dynamic dragState,
    required dynamic dragNotifier,
    required WidgetRef ref,
  }) {
    return TaskDragIntentTarget.insertion(
      key: ValueKey(
        '${config.pageName.toLowerCase()}-insertion-${insertionIndex}',
      ),
        meta: TaskDragIntentMeta(
          page: config.pageName,
          targetType: 'insertionBetween',
          targetId: 'between-$insertionIndex',
          targetTaskId: afterTask.id,
          section: config.section?.name,
        ),
      insertionType: InsertionType.between,
      showWhenIdle: false,
      canAccept: (draggedTask, _) {
        final movable = canMoveTask(draggedTask);
        // 不能拖到自己原来的位置
        return movable &&
            draggedTask.id != beforeTask.id &&
            draggedTask.id != afterTask.id;
      },
      onPerform: (draggedTask, ref, context, l10n) async {
        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          beforeTask,
          afterTask,
          'between',
          config,
          ref,
        );
        dragNotifier.endDrag();
        return result;
      },
      onHover: (isHovering, _) async {
        if (isHovering) {
          _handleExpansionAreaDetection(
            dragState: dragState,
            dragNotifier: dragNotifier,
            flattenedTasks: flattenedTasks,
            filteredTasks: filteredTasks,
            hoveredTaskId: null,
            hoveredInsertionIndex: insertionIndex,
          );
          _updateInsertionHover(dragNotifier, insertionIndex, config.section);
        }
      },
    );
  }

  /// 构建底部插入目标
  static Widget buildBottomInsertionTarget({
    required List<FlattenedTaskNode> flattenedTasks,
    required List<Task> filteredTasks,
    required TaskListConfig config,
    required dynamic dragState,
    required dynamic dragNotifier,
    required WidgetRef ref,
  }) {
    final lastTask = flattenedTasks.last.task;
    return TaskDragIntentTarget.insertion(
      key: ValueKey(
        '${config.pageName.toLowerCase()}-insertion-last',
      ),
        meta: TaskDragIntentMeta(
          page: config.pageName,
          targetType: 'insertionLast',
          targetId: 'last',
          targetTaskId: lastTask.id,
          section: config.section?.name,
        ),
      insertionType: InsertionType.last,
      showWhenIdle: false,
      canAccept: (draggedTask, _) {
        final movable = canMoveTask(draggedTask);
        // 不能拖到自己原来的位置
        return movable && draggedTask.id != lastTask.id;
      },
      onPerform: (draggedTask, ref, context, l10n) async {
        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          lastTask, // beforeTask 是最后一个任务
          null, // afterTask 为 null（底部插入）
          'last',
          config,
          ref,
        );
        dragNotifier.endDrag();
        return result;
      },
      onHover: (isHovering, _) async {
        if (isHovering) {
          _handleExpansionAreaDetection(
            dragState: dragState,
            dragNotifier: dragNotifier,
            flattenedTasks: flattenedTasks,
            filteredTasks: filteredTasks,
            hoveredTaskId: null,
            hoveredInsertionIndex: flattenedTasks.length,
          );
          _updateInsertionHover(
            dragNotifier,
            flattenedTasks.length,
            config.section,
          );
        }
      },
    );
  }

  /// 处理扩展区检测
  static void _handleExpansionAreaDetection({
    required dynamic dragState,
    required dynamic dragNotifier,
    required List<FlattenedTaskNode> flattenedTasks,
    required List<Task> filteredTasks,
    required int? hoveredTaskId,
    required int? hoveredInsertionIndex,
  }) {
    final draggedTask = dragState?.draggedTask;
    if (draggedTask == null) return;

    final movedOut = TaskListExpansionDetector.isMovedOutOfExpandedArea(
      draggedTask,
      hoveredTaskId,
      hoveredInsertionIndex,
      flattenedTasks,
      filteredTasks,
    );

    if (movedOut) {
      dragNotifier.setDraggedTaskHidden(true);
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: movedOutOfExpansion, taskId: ${draggedTask.id}, action: hideFromUI}',
        );
      }
    } else {
      if (dragState.isDraggedTaskHiddenFromExpansion == true) {
        dragNotifier.setDraggedTaskHidden(false);
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: movedBackToExpansion, taskId: ${draggedTask.id}, action: showInUI}',
          );
        }
      }
    }
  }

  /// 更新插入位置悬停状态
  static void _updateInsertionHover(
    dynamic dragNotifier,
    int insertionIndex,
    TaskSection? section,
  ) {
    // 尝试调用带 section 参数的方法（TasksDragNotifier）
    try {
      dragNotifier.updateInsertionHover(insertionIndex, section);
    } catch (e) {
      // 如果失败，尝试调用不带 section 参数的方法（InboxDragNotifier）
      dragNotifier.updateInsertionHover(insertionIndex);
    }
  }
}

