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
    String? getTargetId() {
      switch (targetType) {
        case InboxDragTargetType.between:
          return beforeTask?.id;
        case InboxDragTargetType.first:
          return 'first'; // 列表开头固定ID
        case InboxDragTargetType.last:
          return 'last'; // 列表结尾固定ID
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
          // 同时更新新旧两套API，确保状态同步
          dragNotifier.updateHoverTarget(targetType, targetId: targetId);
          
          // 根据 targetType 计算并更新 insertionIndex
            int? insertionIndex;
          switch (targetType) {
            case InboxDragTargetType.first:
              insertionIndex = 0;
              break;
              case InboxDragTargetType.last:
                // last 的插入索引由外部设定，这里不更新
                break;
            case InboxDragTargetType.between:
              // between 类型需要根据 beforeTask/afterTask 计算，暂时保留旧的 API
              break;
          }
          
          if (insertionIndex != null) {
            dragNotifier.updateInsertionHover(insertionIndex);
          }
        } else {
            dragNotifier.updateHoverTarget(null);
            dragNotifier.clearHover();
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
    // 统一接受根任务和子任务，都使用"成为兄弟"的逻辑
    // 检查任务是否可移动
    final movable = canMoveTask(draggedTask);
    
    if (kDebugMode) {
      // 根据不同类型计算唯一ID
      String? targetId;
      switch (targetType) {
        case InboxDragTargetType.between:
          targetId = 'between:${beforeTask?.id ?? 'null'}:${afterTask?.id ?? 'null'}';
          break;
        case InboxDragTargetType.first:
          targetId = 'first';
          break;
        case InboxDragTargetType.last:
          targetId = 'last';
          break;
      }
      
      // 详细记录 canAccept 检查的每个步骤
      final steps = <String, Object?>{
        'movable': movable,
        'status': draggedTask.status.name,
        'parentId': draggedTask.parentId,
        'beforeTask': beforeTask?.id,
        'afterTask': afterTask?.id,
      };
      
      String reason = '';
      if (!movable) {
        reason = 'task is not movable (status: ${draggedTask.status.name})';
      }
      
      debugPrint(
        '[DnD] {event: canAccept:check, page: Inbox, tgtType: $targetType, tgtId: $targetId, src: ${draggedTask.id}, steps: $steps, result: $movable, reason: ${reason.isNotEmpty ? "\"$reason\"" : "null"}}',
      );
    }
    
    return movable;
  }

  Future<TaskDragIntentResult> _handleDrop(
    Task draggedTask,
    WidgetRef ref,
    InboxDragNotifier dragNotifier,
  ) async {
    try {
      final taskHierarchyService = await ref.read(taskHierarchyServiceProvider.future);
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final dragState = ref.read(inboxDragProvider);
      
      // 确定上方任务的 parentId
    String? aboveTaskParentId;
      double newSortIndex;
      
      switch (targetType) {
        case InboxDragTargetType.first:
          // 顶部插入目标：成为根项目（parentId = null）
          aboveTaskParentId = null;
          newSortIndex = beforeTask?.sortIndex != null
              ? beforeTask!.sortIndex - 1000
              : TaskConstants.DEFAULT_SORT_INDEX - 1000;
          break;
          
        case InboxDragTargetType.between:
          // 中间插入目标：需要判断 beforeTask 和 afterTask 是否是兄弟
          if (beforeTask != null && afterTask != null) {
            // 判断是否是兄弟（同一 parentId）
            final areSiblings = beforeTask!.parentId == afterTask!.parentId;
            
            if (areSiblings) {
              // 是兄弟：成为 beforeTask 的兄弟
              aboveTaskParentId = beforeTask!.parentId;
            } else {
              // 不是兄弟（不同级别）：根据向右拖动情况决定
              // 使用异步方法计算层级深度
                final beforeDepth = await calculateHierarchyDepth(beforeTask!, taskRepository);
                final afterDepth = await calculateHierarchyDepth(afterTask!, taskRepository);
              
              // 从 dragState 获取水平位移
              final horizontalOffset = dragState.horizontalOffset ?? 0.0;
              final isRightDrag = horizontalOffset > 30.0;
              
              if (kDebugMode) {
                debugPrint(
                  '[DnD] {event: betweenNotSiblings, page: Inbox, before: ${beforeTask!.id} (depth: $beforeDepth), after: ${afterTask!.id} (depth: $afterDepth), horizontalOffset: $horizontalOffset, isRightDrag: $isRightDrag}',
                );
              }
              
              if (isRightDrag) {
                // 向右拖动：成为层级较深的那个任务的兄弟
                aboveTaskParentId = beforeDepth > afterDepth 
                    ? beforeTask!.parentId 
                    : afterTask!.parentId;
              } else {
                // 没有向右拖动：成为层级较浅的那个任务的兄弟
                aboveTaskParentId = beforeDepth < afterDepth 
                    ? beforeTask!.parentId 
                    : afterTask!.parentId;
              }
            }
            
            // 计算 sortIndex
            newSortIndex = (beforeTask!.sortIndex + afterTask!.sortIndex) / 2;
          } else {
            // 如果 beforeTask 或 afterTask 为 null，使用默认值
            aboveTaskParentId = beforeTask?.parentId;
            newSortIndex = TaskConstants.DEFAULT_SORT_INDEX;
          }
          break;
          
        case InboxDragTargetType.last:
          // 底部插入目标：最后一个任务作为 beforeTask（afterTask = null）
          // 成为最后一个任务的兄弟
          aboveTaskParentId = beforeTask?.parentId;
          newSortIndex = beforeTask?.sortIndex != null
              ? beforeTask!.sortIndex + 1000
              : TaskConstants.DEFAULT_SORT_INDEX + 1000;
          break;
      }

      // 统一使用 moveToParent 处理
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: call:moveToParent, page: Inbox, src: ${draggedTask.id}, parentId: $aboveTaskParentId, sortIndex: $newSortIndex}',
        );
      }
      
      await taskHierarchyService.moveToParent(
        taskId: draggedTask.id,
        parentId: aboveTaskParentId,
        sortIndex: newSortIndex,
        clearParent: aboveTaskParentId == null,
      );

      // 批量重排所有inbox任务的sortIndex
      final sortIndexService = await ref.read(sortIndexServiceProvider.future);
      final allInboxTasks = await taskRepository.watchInbox().first;
      await sortIndexService.reorderTasksForInbox(tasks: allInboxTasks);
      
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: reorderTasksForInbox:completed, page: Inbox, taskCount: ${allInboxTasks.length}}',
        );
      }
      
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:success, page: Inbox, src: ${draggedTask.id}, parentId: $aboveTaskParentId, sortIndex: $newSortIndex}',
        );
      }
      
      // 直接回读数据库确认 parentId 等字段
      try {
        final saved = await taskRepository.findById(draggedTask.id);
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: db:readback, page: Inbox, task: ${draggedTask.id}, parentId: ${saved?.parentId}, status: ${saved?.status}, sortIndex: ${saved?.sortIndex}}',
          );
        }
      } catch (_) {}
      
      // 如果提升为根项目，触发回调
      if (aboveTaskParentId == null) {
        onPromoteToRoot?.call(draggedTask, newSortIndex);
      }
      
      return TaskDragIntentResult.success(
        parentId: aboveTaskParentId,
        sortIndex: newSortIndex,
        clearParent: aboveTaskParentId == null,
      );
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
  }
}
