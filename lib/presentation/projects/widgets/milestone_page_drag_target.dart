import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../../core/providers/tasks_drag_provider.dart';
import '../../common/drag/task_drag_intent_target.dart';
import '../../common/drag/standard_drag_target.dart';
import '../../common/task_list/task_list_insertion_handler.dart';
import '../../tasks/tasks_drag_target_type.dart';
import 'milestone_task_list_config.dart';

/// 里程碑页面拖拽目标组件
///
/// 支持在任务之间插入拖拽目标，提供视觉反馈和拖拽处理
/// 参考 TasksPageDragTarget 的实现
class MilestonePageDragTarget extends ConsumerWidget {
  const MilestonePageDragTarget({
    super.key,
    required this.targetType,
    required this.milestoneId,
    this.beforeTask,
    this.afterTask,
    this.child,
  });

  final TasksDragTargetType targetType;
  final String milestoneId;
  final Task? beforeTask;
  final Task? afterTask;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragNotifier = ref.read(tasksDragProvider.notifier);

    // 根据不同类型计算唯一ID
    String? getTargetId() {
      switch (targetType) {
        case TasksDragTargetType.first:
          return 'first';
        case TasksDragTargetType.between:
          return beforeTask?.id;
        case TasksDragTargetType.last:
          return 'last';
      }
    }

    final targetId = getTargetId();

    return TaskDragIntentTarget.insertion(
      meta: TaskDragIntentMeta(
        page: 'ProjectDetail',
        targetType: targetType.name,
        targetId: targetId,
        section: null, // 里程碑不是基于 section 的
        targetTaskId: targetType == TasksDragTargetType.first
            ? afterTask?.id
            : (afterTask?.id ?? beforeTask?.id),
      ),
      insertionType: _mapToInsertionType(targetType),
      showWhenIdle: false,
      insertionChild: child,
      canAccept: (dragged, _) => _canAcceptDrop(dragged),
      onPerform: (dragged, ref, context, l10n) async {
        try {
          return await _handleDrop(dragged, ref);
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: accept:error, page: ProjectDetail, tgtType: $targetType, tgtId: $targetId, milestoneId: $milestoneId, src: ${dragged.id}, error: $e}',
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

  InsertionType _mapToInsertionType(TasksDragTargetType type) {
    switch (type) {
      case TasksDragTargetType.first:
        return InsertionType.first;
      case TasksDragTargetType.between:
        return InsertionType.between;
      case TasksDragTargetType.last:
        return InsertionType.last;
    }
  }

  bool _canAcceptDrop(Task draggedTask) {
    switch (targetType) {
      case TasksDragTargetType.first:
        // 不能拖拽到自己原来的位置
        if (afterTask?.id == draggedTask.id) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: block, page: ProjectDetail, reason: selfFirst, src: ${draggedTask.id}, after: ${afterTask?.id}}',
            );
          }
          return false;
        }
        // 需要 afterTask 存在（列表不为空）
        final ok = afterTask != null;
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: rule, page: ProjectDetail, rule: firstNeighborPresent, src: ${draggedTask.id}, ok: $ok, after: ${afterTask?.id}}',
          );
        }
        return ok;
      case TasksDragTargetType.between:
        // 不能拖拽到自己上方或下方
        if (beforeTask?.id == draggedTask.id ||
            afterTask?.id == draggedTask.id) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: block, page: ProjectDetail, reason: selfAdjacent, src: ${draggedTask.id}, before: ${beforeTask?.id}, after: ${afterTask?.id}}',
            );
          }
          return false;
        }
        // 需要 beforeTask 和 afterTask 都存在
        final ok = beforeTask != null && afterTask != null;
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: rule, page: ProjectDetail, rule: betweenNeighborsPresent, src: ${draggedTask.id}, ok: $ok, before: ${beforeTask?.id}, after: ${afterTask?.id}}',
          );
        }
        return ok;
      case TasksDragTargetType.last:
        // 不能拖拽到自己原来的位置
        if (beforeTask?.id == draggedTask.id) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: block, page: ProjectDetail, reason: selfLast, src: ${draggedTask.id}, before: ${beforeTask?.id}}',
            );
          }
          return false;
        }
        // 需要 beforeTask 存在（列表不为空）
        final ok = beforeTask != null;
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: rule, page: ProjectDetail, rule: lastNeighborPresent, src: ${draggedTask.id}, ok: $ok, before: ${beforeTask?.id}}',
          );
        }
        return ok;
    }
  }

  Future<TaskDragIntentResult> _handleDrop(Task draggedTask, WidgetRef ref) async {
    // 使用 TaskListInsertionHandler 处理拖拽逻辑
    final config = MilestoneTaskListConfig(milestoneId);
    return TaskListInsertionHandler.handleInsertionDrop(
      draggedTask,
      beforeTask,
      afterTask,
      targetType.name,
      config,
      ref,
    );
  }
}

