import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../tasks/utils/hierarchy_utils.dart';
import '../common/drag/task_drag_intent_target.dart';

/// 任务拖拽意图处理辅助类
///
/// 从 TaskTileContent 中提取的拖拽逻辑，用于在列表组件中复用。
/// 提供统一的拖拽接受检查和放置处理逻辑。
class TaskDragIntentHelper {
  TaskDragIntentHelper._();

  /// 同步检查是否可以将 draggedTask 作为 targetTask 的子任务
  ///
  /// 这个方法只做可以同步检查的基本验证，异步的深度检查在 handleDropOnTask 中完成
  static bool canAcceptAsChild(Task draggedTask, Task targetTask) {
    // 不能拖拽到自己
    if (draggedTask.id == targetTask.id) {
      return false;
    }
    // 不能拖拽到自己的直接父任务上（避免无效操作）
    if (draggedTask.parentId == targetTask.id) {
      return false;
    }
    // 检查 target task 是否被锁定（不能添加子任务）
    if (!canAcceptChildren(targetTask)) {
      return false;
    }
    // 检查 dragged task 是否被锁定（不能移动）
    if (!canMoveTask(draggedTask)) {
      return false;
    }
    return true;
  }

  /// 处理拖拽放置到目标任务上的逻辑
  ///
  /// 执行所有验证（包括同步和异步），然后执行实际的移动操作。
  static Future<TaskDragIntentResult> handleDropOnTask(
    Task draggedTask,
    Task targetTask,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) async {
    final effectiveL10n = l10n ?? AppLocalizations.of(context);
    try {
      final taskHierarchyService = ref.read(taskHierarchyServiceProvider);
      final taskRepository = ref.read(taskRepositoryProvider);

      // 放手后进行同步规则拦截并提示
      // 1) 不能拖到自身或其直接父任务
      if (draggedTask.id == targetTask.id ||
          draggedTask.parentId == targetTask.id) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: block:selfOrParent, src: ${draggedTask.id}, tgt: ${targetTask.id}}',
          );
        }
        if (!context.mounted) {
          return const TaskDragIntentResult.blocked(
            blockReasonKey: 'taskMoveBlockedSelfOrParent',
            blockLogTag: 'selfOrParent',
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(effectiveL10n.taskMoveBlockedSelfOrParent)),
        );
        return const TaskDragIntentResult.blocked(
          blockReasonKey: 'taskMoveBlockedSelfOrParent',
          blockLogTag: 'selfOrParent',
        );
      }
      // 2) 目标不允许添加子任务
      if (!canAcceptChildren(targetTask)) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: block:targetLocked, src: ${draggedTask.id}, tgt: ${targetTask.id}}',
          );
        }
        if (!context.mounted) {
          return const TaskDragIntentResult.blocked(
            blockReasonKey: 'taskMoveBlockedTargetLocked',
            blockLogTag: 'targetLocked',
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(effectiveL10n.taskMoveBlockedTargetLocked)),
        );
        return const TaskDragIntentResult.blocked(
          blockReasonKey: 'taskMoveBlockedTargetLocked',
          blockLogTag: 'targetLocked',
        );
      }
      // 3) 当前任务不可移动
      if (!canMoveTask(draggedTask)) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: block:sourceLocked, src: ${draggedTask.id}, tgt: ${targetTask.id}}',
          );
        }
        if (!context.mounted) {
          return const TaskDragIntentResult.blocked(
            blockReasonKey: 'taskMoveBlockedSourceLocked',
            blockLogTag: 'sourceLocked',
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(effectiveL10n.taskMoveBlockedSourceLocked)),
        );
        return const TaskDragIntentResult.blocked(
          blockReasonKey: 'taskMoveBlockedSourceLocked',
          blockLogTag: 'sourceLocked',
        );
      }

      // 异步验证循环引用（在 Service 层也会验证，但这里提前验证可以避免不必要的计算）
      if (await hasCircularReference(
        draggedTask,
        targetTask.id,
        taskRepository,
      )) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: block:cycle, src: ${draggedTask.id}, tgt: ${targetTask.id}}',
          );
        }
        if (!context.mounted) {
          return const TaskDragIntentResult.blocked(
            blockReasonKey: 'taskMoveBlockedCycle',
            blockLogTag: 'cycle',
          );
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(effectiveL10n.taskMoveBlockedCycle)));
        return const TaskDragIntentResult.blocked(
          blockReasonKey: 'taskMoveBlockedCycle',
          blockLogTag: 'cycle',
        );
      }

      // 层级深度限制校验：根=0，第1=1，第2=2；拖拽后最大不能超过 2
      final targetDepth = await calculateHierarchyDepth(
        targetTask,
        taskRepository,
      );
      final subtreeDepth = await calculateSubtreeDepth(
        draggedTask,
        taskRepository,
      );
      if (targetDepth + subtreeDepth > 2) {
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: block:depth, src: ${draggedTask.id}, tgt: ${targetTask.id}, targetDepth: $targetDepth, subtreeDepth: $subtreeDepth}',
          );
        }
        if (!context.mounted) {
          return const TaskDragIntentResult.blocked(
            blockReasonKey: 'taskMoveBlockedDepth',
            blockLogTag: 'depth',
          );
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(effectiveL10n.taskMoveBlockedDepth)));
        return const TaskDragIntentResult.blocked(
          blockReasonKey: 'taskMoveBlockedDepth',
          blockLogTag: 'depth',
        );
      }

      // 使用 Service 层的计算方法计算 sortIndex
      final newSortIndex = await taskHierarchyService
          .calculateSortIndexForNewChild(targetTask.id);

      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: call:moveToParent, src: ${draggedTask.id}, parent: ${targetTask.id}}',
        );
      }
      await taskHierarchyService.moveToParent(
        taskId: draggedTask.id,
        parentId: targetTask.id,
        sortIndex: newSortIndex,
      );

      if (!context.mounted) {
        return TaskDragIntentResult.success(
          parentId: targetTask.id,
          sortIndex: newSortIndex,
        );
      }

      // 可选：显示成功提示（如果需要的话，可以取消注释）
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text(effectiveL10n.taskBecameSubtask ?? 'Task became subtask')),
      // );
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:success, src: ${draggedTask.id}, tgt: ${targetTask.id}}',
        );
      }
      return TaskDragIntentResult.success(
        parentId: targetTask.id,
        sortIndex: newSortIndex,
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:error, src: ${draggedTask.id}, tgt: ${targetTask.id}, error: $error}',
        );
        debugPrint('$stackTrace');
      }
      if (!context.mounted) {
        return const TaskDragIntentResult.blocked(
          blockReasonKey: 'taskMoveBlockedUnknown',
          blockLogTag: 'unknown',
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(effectiveL10n.taskMoveBlockedUnknown)));
      return const TaskDragIntentResult.blocked(
        blockReasonKey: 'taskMoveBlockedUnknown',
        blockLogTag: 'unknown',
      );
    }
  }
}
