import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task.dart';
import '../../generated/l10n/app_localizations.dart';
import '../tasks/utils/hierarchy_utils.dart';
import 'task_row_content.dart';
import '../common/drag/standard_draggable.dart';
import '../common/drag/task_drag_intent_target.dart';

/// 统一的任务卡片内容布局
///
/// 包含：
/// - 左侧拖拽指示器（drag_indicator 图标）
/// - 右侧任务内容（TaskRowContent，支持 inline 编辑）
/// - 拖拽到任务上时，可将被拖拽的 task 变成子任务（DragTarget）
///
/// 用于 Inbox 和 Tasks 页面，确保视觉和交互的完全一致性。
///
/// 使用方式：
/// ```dart
/// TaskTileContent(task: myTask)
/// ```
class TaskTileContent extends ConsumerStatefulWidget {
  const TaskTileContent({
    super.key,
    required this.task,
    this.compact = false,
    this.leading,
    this.contentPadding,
    this.dragPage = 'Tasks',
  });

  final Task task;
  final bool compact;
  final Widget? leading;
  final EdgeInsetsGeometry? contentPadding;
  final String dragPage;

  @override
  ConsumerState<TaskTileContent> createState() => _TaskTileContentState();
}

class _TaskTileContentState extends ConsumerState<TaskTileContent> {
  @override
  Widget build(BuildContext context) {
    return TaskDragIntentTarget.surface(
      meta: TaskDragIntentMeta(
        page: widget.dragPage,
        targetType: 'taskSurface',
        targetId: widget.task.id,
        targetTaskId: widget.task.id,
      ),
      canAccept: (draggedTask, _) =>
          _canAcceptAsChildSync(draggedTask, widget.task),
      onPerform: (draggedTask, ref, context, l10n) async {
        final effectiveL10n = l10n ?? AppLocalizations.of(context);
        return _handleDropOnTask(
          draggedTask,
          widget.task,
          context,
          ref,
          effectiveL10n,
        );
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final handle = widget.leading != null
        ? Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: widget.leading!,
          )
        : Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: Icon(
              Icons.drag_indicator,
              color: Colors.grey[400],
              size: 20,
            ),
          );

    return Padding(
      padding:
          widget.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: StandardDraggable<Task>(
        data: widget.task,
        handle: handle,
        child: TaskRowContent(task: widget.task, compact: widget.compact),
      ),
    );
  }

  /// 同步检查是否可以将 draggedTask 作为 targetTask 的子任务
  ///
  /// 这个方法只做可以同步检查的基本验证，异步的深度检查在 onAccept 中完成
  bool _canAcceptAsChildSync(Task draggedTask, Task targetTask) {
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

  Future<TaskDragIntentResult> _handleDropOnTask(
    Task draggedTask,
    Task targetTask,
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
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
          SnackBar(content: Text(l10n.taskMoveBlockedSelfOrParent)),
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
          SnackBar(content: Text(l10n.taskMoveBlockedTargetLocked)),
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
          SnackBar(content: Text(l10n.taskMoveBlockedSourceLocked)),
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
        ).showSnackBar(SnackBar(content: Text(l10n.taskMoveBlockedCycle)));
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
        ).showSnackBar(SnackBar(content: Text(l10n.taskMoveBlockedDepth)));
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
      //   SnackBar(content: Text(l10n.taskBecameSubtask ?? 'Task became subtask')),
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
      ).showSnackBar(SnackBar(content: Text(l10n.taskMoveBlockedUnknown)));
      return const TaskDragIntentResult.blocked(
        blockReasonKey: 'taskMoveBlockedUnknown',
        blockLogTag: 'unknown',
      );
    }
  }
}
