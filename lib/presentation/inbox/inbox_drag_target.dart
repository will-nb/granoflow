import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/task_constants.dart';
import '../../data/models/task.dart';
import '../../core/providers/inbox_drag_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../core/providers/repository_providers.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
import '../common/drag/standard_drag_target.dart';
import '../common/drag/task_drag_intent_target.dart';

/// Inbox页面拖拽目标组件
///
/// 支持3种拖拽目标类型，提供视觉反馈和拖拽处理
class InboxDragTarget extends ConsumerWidget {
  const InboxDragTarget({
    super.key,
    required this.targetType,
    this.beforeTask,
    this.afterTask,
    this.onPromoteToRoot,
  });

  final InboxDragTargetType targetType;
  final Task? beforeTask;
  final Task? afterTask;
  final void Function(Task draggedTask, double newSortIndex)? onPromoteToRoot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragNotifier = ref.read(inboxDragProvider.notifier);

    // 根据不同类型计算唯一ID
    int? getTargetId() {
      switch (targetType) {
        case InboxDragTargetType.between:
          return beforeTask?.id;
        case InboxDragTargetType.first:
          return 0; // 列表开头固定ID
        case InboxDragTargetType.last:
          return -1; // 列表结尾固定ID
      }
    }

    final targetId = getTargetId();

    return TaskDragIntentTarget.insertion(
      meta: TaskDragIntentMeta(
        page: 'Inbox',
        targetType: targetType.name,
        targetId: targetId,
        targetTaskId: afterTask?.id ?? beforeTask?.id,
      ),
      insertionType: _mapToInsertionType(targetType),
      showWhenIdle: false,
      canAccept: (dragged, _) => _canAcceptDrop(dragged),
      onPerform: (dragged, ref, context, l10n) async {
        try {
          return await _handleDrop(dragged, ref, dragNotifier);
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: accept:error, page: Inbox, tgtType: $targetType, tgtId: $targetId, src: ${dragged.id}, error: $e}',
            );
          }
          return const TaskDragIntentResult.blocked(
            blockReasonKey: 'taskMoveBlockedUnknown',
            blockLogTag: 'exception',
          );
        }
      },
      onHover: (isHovering, _) {
        if (isHovering) {
          dragNotifier.updateHoverTarget(targetType, targetId: targetId);
        } else {
          dragNotifier.updateHoverTarget(null);
        }
      },
      onResult: (_, __, ___, ____, _____) {
        dragNotifier.endDrag();
      },
    );
  }

  InsertionType _mapToInsertionType(InboxDragTargetType type) {
    switch (type) {
      case InboxDragTargetType.between:
        return InsertionType.between;
      case InboxDragTargetType.first:
        return InsertionType.first;
      case InboxDragTargetType.last:
        return InsertionType.last;
    }
  }

  bool _canAcceptDrop(Task draggedTask) {
    // 仅接受“子任务→根级”的提升；根任务排序交给 Reorderable 原生动画
    if (draggedTask.parentId != null) {
      final movable = canMoveTask(draggedTask);
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: rule, page: Inbox, rule: subtaskOnly, src: ${draggedTask.id}, canMove: $movable}',
        );
      }
      return movable;
    }
    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: block, page: Inbox, reason: notSubtask, src: ${draggedTask.id}}',
      );
    }
    return false;
  }

  Future<TaskDragIntentResult> _handleDrop(
    Task draggedTask,
    WidgetRef ref,
    InboxDragNotifier dragNotifier,
  ) async {
    try {
      final taskService = ref.read(taskServiceProvider);
      // 如果是子任务拖拽到根级别，先将其设置为根任务
      if (draggedTask.parentId != null) {
        final taskHierarchyService = ref.read(taskHierarchyServiceProvider);

        // 计算合适的 sortIndex
        double newSortIndex;
        switch (targetType) {
          case InboxDragTargetType.between:
            // 在 beforeTask 和 afterTask 之间
            if (beforeTask != null && afterTask != null) {
              newSortIndex = (beforeTask!.sortIndex + afterTask!.sortIndex) / 2;
            } else {
              newSortIndex = TaskConstants.DEFAULT_SORT_INDEX;
            }
            break;
          case InboxDragTargetType.first:
            // 拖拽到第一个位置，使用较小的 sortIndex
            newSortIndex = beforeTask?.sortIndex != null
                ? beforeTask!.sortIndex - 1000
                : TaskConstants.DEFAULT_SORT_INDEX - 1000;
            break;
          case InboxDragTargetType.last:
            // 拖拽到最后一个位置，使用较大的 sortIndex
            newSortIndex = afterTask?.sortIndex != null
                ? afterTask!.sortIndex + 1000
                : TaskConstants.DEFAULT_SORT_INDEX + 1000;
            break;
        }

        // 将子任务移动到根级别（parentId = null）
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: call:moveToParent, page: Inbox, action: promoteToRoot, src: ${draggedTask.id}, parent: null, sortIndex: $newSortIndex}',
          );
        }
        await taskHierarchyService.moveToParent(
          taskId: draggedTask.id,
          parentId: null,
          sortIndex: newSortIndex,
          clearParent: true,
        );
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: accept:success, page: Inbox, action: promoteToRoot, src: ${draggedTask.id}, sortIndex: $newSortIndex}',
          );
        }
        // 直接回读数据库确认 parentId 等字段
        try {
          final taskRepository = ref.read(taskRepositoryProvider);
          final saved = await taskRepository.findById(draggedTask.id);
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: db:readback, page: Inbox, task: ${draggedTask.id}, parentId: ${saved?.parentId}, status: ${saved?.status}, sortIndex: ${saved?.sortIndex}}',
            );
          }
        } catch (_) {}
        // 乐观更新：通知上层列表立即更新本地数据，避免等待流刷新
        onPromoteToRoot?.call(draggedTask, newSortIndex);

        return const TaskDragIntentResult.success(clearParent: true);
      }

      // 根任务之间的排序逻辑（原有逻辑）
      switch (targetType) {
        case InboxDragTargetType.between:
          await taskService.handleInboxDragBetween(
            draggedTask.id,
            beforeTask!.id,
            afterTask!.id,
          );
          break;
        case InboxDragTargetType.first:
          await taskService.handleInboxDragToFirst(draggedTask.id);
          break;
        case InboxDragTargetType.last:
          await taskService.handleInboxDragToLast(draggedTask.id);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:error, page: Inbox, tgtType: $targetType, src: ${draggedTask.id}, error: $e}',
        );
      }
      return const TaskDragIntentResult.blocked(
        blockReasonKey: 'taskMoveBlockedUnknown',
        blockLogTag: 'serviceError',
      );
    }
    return const TaskDragIntentResult.success();
  }
}
