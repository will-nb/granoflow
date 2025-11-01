import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../data/models/task.dart' as models;
import '../../core/providers/service_providers.dart';
import '../../core/providers/tasks_drag_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../core/utils/task_section_utils.dart';
import '../common/drag/task_drag_intent_target.dart';
import '../common/drag/standard_drag_target.dart';
import 'utils/sort_index_utils.dart';
import 'tasks_drag_target_type.dart';

/// Tasks页面拖拽目标组件
///
/// 支持在任务之间插入拖拽目标，提供视觉反馈和拖拽处理
class TasksPageDragTarget extends ConsumerWidget {
  const TasksPageDragTarget({
    super.key,
    required this.targetType,
    this.beforeTask,
    this.afterTask,
    this.section,
    this.child,
  });

  final TasksDragTargetType targetType;
  final Task? beforeTask;
  final Task? afterTask;
  final models.TaskSection? section;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragNotifier = ref.read(tasksDragProvider.notifier);

    // 根据不同类型计算唯一ID
    int? getTargetId() {
      switch (targetType) {
        case TasksDragTargetType.between:
          return beforeTask?.id;
      }
    }

    final targetId = getTargetId();

    return TaskDragIntentTarget.insertion(
      meta: TaskDragIntentMeta(
        page: 'Tasks',
        targetType: targetType.name,
        targetId: targetId,
        section: section?.name,
        targetTaskId: afterTask?.id ?? beforeTask?.id,
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
              '[DnD] {event: accept:error, page: Tasks, tgtType: $targetType, tgtId: $targetId, section: ${section?.name}, src: ${dragged.id}, error: $e}',
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
      case TasksDragTargetType.between:
        return InsertionType.between;
    }
  }

  bool _canAcceptDrop(Task draggedTask) {
    // 禁止拖拽到已逾期区域
    if (section == models.TaskSection.overdue) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: block, page: Tasks, reason: overdueSection, src: ${draggedTask.id}, section: ${section?.name}}',
        );
      }
      return false;
    }

    switch (targetType) {
      case TasksDragTargetType.between:
        // 不能拖拽到自己上方或下方
        if (beforeTask?.id == draggedTask.id ||
            afterTask?.id == draggedTask.id) {
          if (kDebugMode) {
            debugPrint(
              '[DnD] {event: block, page: Tasks, reason: selfAdjacent, src: ${draggedTask.id}, before: ${beforeTask?.id}, after: ${afterTask?.id}}',
            );
          }
          return false;
        }
        // 移除 dueAt 限制，支持跨区域拖拽
        final ok = beforeTask != null && afterTask != null;
        if (kDebugMode) {
          debugPrint(
            '[DnD] {event: rule, page: Tasks, rule: betweenNeighborsPresent, src: ${draggedTask.id}, ok: $ok, before: ${beforeTask?.id}, after: ${afterTask?.id}}',
          );
        }
        return ok;
    }
  }

  Future<TaskDragIntentResult> _handleDrop(
    Task draggedTask,
    WidgetRef ref,
  ) async {
    try {
      final now = DateTime.now();
      final currentSection = TaskSectionUtils.getSectionForDate(
        draggedTask.dueAt,
        now: now,
      );
      final models.TaskSection targetSection = section ?? currentSection;
      final _SortContext context = _computeSortContext(draggedTask);
      final newSortIndex = context.sortIndex;
      final newDueDate = _computeDueDate(
        sortContext: context,
        draggedTask: draggedTask,
        now: now,
        currentSection: currentSection,
        targetSection: targetSection,
      );

      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: drop:start, page: Tasks, tgtType: $targetType, src: ${draggedTask.id}, taskKind: ${draggedTask.taskKind}, status: ${draggedTask.status}, currentSection: $currentSection, targetSection: $targetSection, oldDueAt: ${draggedTask.dueAt}, newDueAt: $newDueDate, newSortIndex: $newSortIndex, oldSortIndex: ${draggedTask.sortIndex}}',
        );
        debugPrint(
          '[DnD] {neighbors: beforeTask: ${context.previous?.id} (dueAt: ${context.previous?.dueAt}, section: ${context.previous != null ? TaskSectionUtils.getSectionForDate(context.previous!.dueAt, now: now) : null}), afterTask: ${context.next?.id} (dueAt: ${context.next?.dueAt}, section: ${context.next != null ? TaskSectionUtils.getSectionForDate(context.next!.dueAt, now: now) : null})}',
        );
      }

      // 记录拖拽前的任务分布
      if (kDebugMode) {
        final taskRepo = ref.read(taskRepositoryProvider);
        try {
          final currentSectionTasks = await taskRepo.listSectionTasks(currentSection);
          final targetSectionTasks = await taskRepo.listSectionTasks(targetSection);
          debugPrint(
            '[DnD] {before: currentSection=$currentSection, taskCount=${currentSectionTasks.length}, targetSection=$targetSection, taskCount=${targetSectionTasks.length}}',
          );
          if (currentSectionTasks.isNotEmpty) {
            debugPrint('[DnD] {currentSectionTasks (前5个):');
            for (final task in currentSectionTasks.take(5)) {
              debugPrint('  id=${task.id}, title="${task.title}", dueAt=${task.dueAt}, sortIndex=${task.sortIndex}, taskKind=${task.taskKind}, status=${task.status}');
            }
            debugPrint('}');
          }
          if (targetSectionTasks.isNotEmpty) {
            debugPrint('[DnD] {targetSectionTasks (前5个):');
            for (final task in targetSectionTasks.take(5)) {
              debugPrint('  id=${task.id}, title="${task.title}", dueAt=${task.dueAt}, sortIndex=${task.sortIndex}, taskKind=${task.taskKind}, status=${task.status}');
            }
            debugPrint('}');
          }
        } catch (e) {
          debugPrint('[DnD] {error: 获取拖拽前任务分布失败: $e}');
        }
      }

      final taskService = ref.read(taskServiceProvider);
      await taskService.updateDetails(
        taskId: draggedTask.id,
        payload: TaskUpdate(sortIndex: newSortIndex, dueAt: newDueDate),
      );

      // 记录拖拽后的任务分布（延迟一小段时间让数据库更新完成）
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 100));
        final taskRepo = ref.read(taskRepositoryProvider);
        try {
          final currentSectionTasksAfter = await taskRepo.listSectionTasks(currentSection);
          final targetSectionTasksAfter = await taskRepo.listSectionTasks(targetSection);
          debugPrint(
            '[DnD] {after: currentSection=$currentSection, taskCount=${currentSectionTasksAfter.length}, targetSection=$targetSection, taskCount=${targetSectionTasksAfter.length}}',
          );
          // 检查被拖拽的任务是否在目标区域
          final taskInTarget = targetSectionTasksAfter.any((t) => t.id == draggedTask.id);
          final taskInCurrent = currentSectionTasksAfter.any((t) => t.id == draggedTask.id);
          debugPrint(
            '[DnD] {validation: task ${draggedTask.id} inTarget=$taskInTarget, inCurrent=$taskInCurrent, expectedInTarget=${currentSection != targetSection}}',
          );
          if (targetSectionTasksAfter.isNotEmpty) {
            debugPrint('[DnD] {targetSectionTasksAfter (前10个):');
            for (final task in targetSectionTasksAfter.take(10)) {
              debugPrint('  id=${task.id}, title="${task.title}", dueAt=${task.dueAt}, sortIndex=${task.sortIndex}, taskKind=${task.taskKind}, status=${task.status}');
            }
            debugPrint('}');
          }
        } catch (e) {
          debugPrint('[DnD] {error: 获取拖拽后任务分布失败: $e}');
        }
      }

      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:success, page: Tasks, tgtType: $targetType, src: ${draggedTask.id}, sortIndex: $newSortIndex, dueAt: $newDueDate}',
        );
      }
      return TaskDragIntentResult.success(
        sortIndex: newSortIndex,
        dueDate: newDueDate,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: accept:error, page: Tasks, tgtType: $targetType, src: ${draggedTask.id}, error: $e, stackTrace: $stackTrace}',
        );
      }
      return const TaskDragIntentResult.blocked(
        blockReasonKey: 'taskMoveBlockedUnknown',
        blockLogTag: 'updateError',
      );
    }
  }

  _SortContext _computeSortContext(Task draggedTask) {
    if (beforeTask == null && afterTask == null) {
      return _SortContext(
        sortIndex: draggedTask.sortIndex,
        previous: null,
        next: null,
      );
    }
    switch (targetType) {
      case TasksDragTargetType.between:
        return _SortContext(
          sortIndex: calculateSortIndex(
            beforeTask?.sortIndex,
            afterTask?.sortIndex,
          ),
          previous: beforeTask,
          next: afterTask,
        );
    }
  }

  DateTime? _computeDueDate({
    required _SortContext sortContext,
    required Task draggedTask,
    required DateTime now,
    required models.TaskSection currentSection,
    required models.TaskSection targetSection,
  }) {
    final before = sortContext.previous;
    final after = sortContext.next;
    final beforeDue = before?.dueAt;
    final afterDue = after?.dueAt;
    final hasBefore = before != null;
    final hasAfter = after != null;

    if (targetSection == currentSection) {
      // 同一区域内，优先使用邻居任务的 dueAt
      if (hasBefore && beforeDue != null) {
        return beforeDue;
      }
      if (!hasBefore && hasAfter && afterDue != null) {
        return afterDue;
      }
      return draggedTask.dueAt;
    }

    // 跨区域拖拽
    // 优先使用邻居任务的 dueAt（如果邻居也在目标区域）
    if (hasBefore && beforeDue != null) {
      final beforeSection = TaskSectionUtils.getSectionForDate(beforeDue, now: now);
      if (beforeSection == targetSection) {
      return beforeDue;
      }
    }
    if (!hasBefore && hasAfter && afterDue != null) {
      final afterSection = TaskSectionUtils.getSectionForDate(afterDue, now: now);
      if (afterSection == targetSection) {
      return afterDue;
    }
    }

    // 如果没有有效的邻居任务，使用目标区域的结束时间（23:59:59）
    // 这样可以确保任务被包含在目标区域的查询范围内
    return TaskSectionUtils.getSectionEndTime(targetSection, now: now);
  }
}

class _SortContext {
  const _SortContext({required this.sortIndex, this.previous, this.next});

  final double sortIndex;
  final Task? previous;
  final Task? next;
}
