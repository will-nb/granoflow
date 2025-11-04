import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import '../utils/task_section_utils.dart';
import 'metric_orchestrator.dart';
import 'sort_index_service.dart';

/// 任务拖拽服务
/// 处理任务拖拽相关的操作，包括任务间拖拽、区域拖拽、Inbox 拖拽等
class TaskDragService {
  TaskDragService({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    SortIndexService? sortIndexService,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _sortIndex = sortIndexService,
       _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final SortIndexService? _sortIndex;
  final DateTime Function() _clock;

  /// 处理拖拽到任务间（调整sortIndex，支持跨区域）
  Future<void> handleDragBetweenTasks(
    int draggedTaskId,
    int beforeTaskId,
    int afterTaskId,
  ) async {
    debugPrint(
      '拖拽排序Between: task=$draggedTaskId between $beforeTaskId/$afterTaskId',
    );

    // 获取任务信息以检测是否跨区域
    final draggedTask = await _tasks.findById(draggedTaskId);
    final beforeTask = await _tasks.findById(beforeTaskId);
    final afterTask = await _tasks.findById(afterTaskId);

    if (draggedTask == null || beforeTask == null || afterTask == null) {
      debugPrint('任务不存在，取消拖拽');
      return;
    }

    // 检测目标区域（使用 beforeTask 的 section）
    final targetSection = _getSectionForTask(beforeTask);
    final currentSection = _getSectionForTask(draggedTask);

    // 如果跨区域拖拽，先更新 dueAt
    if (targetSection != currentSection && beforeTask.dueAt != null) {
      final sectionEndTime = _getSectionEndTime(targetSection);
      debugPrint(
        '跨区域拖拽: $currentSection -> $targetSection, 更新 dueAt 为 $sectionEndTime',
      );
      await _tasks.updateTask(draggedTaskId, TaskUpdate(dueAt: sectionEndTime));
    }

    // 执行排序逻辑
    final sortIndex = _sortIndex;
    if (sortIndex != null) {
      await sortIndex.insertBetween(
        draggedId: draggedTaskId,
        beforeId: beforeTaskId,
        afterId: afterTaskId,
      );
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 根据任务的 dueAt 获取其所属区域
  TaskSection _getSectionForTask(Task task) {
    return TaskSectionUtils.getSectionForDate(task.dueAt, now: _clock());
  }

  /// 处理拖拽到区域首位
  Future<void> handleDragToSectionFirst(
    int draggedTaskId,
    TaskSection section,
  ) async {
    final sectionEndTime = _getSectionEndTime(section);
    debugPrint('拖拽到区域首位: task=$draggedTaskId, section=$section');
    await _tasks.updateTask(draggedTaskId, TaskUpdate(dueAt: sectionEndTime));
    // 找到区域首元素（排除自身），调用 moveToHead
    final tasks = await _tasks.listSectionTasks(section);
    final others = tasks
        .where((t) => t.id != draggedTaskId)
        .toList(growable: false);
    if (others.isEmpty) {
      if (_sortIndex != null) {
        await _tasks.updateTask(
          draggedTaskId,
          const TaskUpdate(sortIndex: 1024),
        );
      }
    } else {
      final first = others.first;
      final sortIndex = _sortIndex;
      if (sortIndex != null) {
        await sortIndex.moveToHead(
          draggedId: draggedTaskId,
          section: section,
          firstId: first.id,
        );
      }
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 处理拖拽到区域末位
  Future<void> handleDragToSectionLast(
    int draggedTaskId,
    TaskSection section,
  ) async {
    final sectionEndTime = _getSectionEndTime(section);
    debugPrint('拖拽到区域末位: task=$draggedTaskId, section=$section');
    await _tasks.updateTask(draggedTaskId, TaskUpdate(dueAt: sectionEndTime));
    final tasks = await _tasks.listSectionTasks(section);
    final sortIndex = _sortIndex;
    if (sortIndex != null) {
      final others = tasks
          .where((t) => t.id != draggedTaskId)
          .toList(growable: false);
      if (others.isEmpty) {
        await _tasks.updateTask(
          draggedTaskId,
          const TaskUpdate(sortIndex: 1024),
        );
      } else {
        final lastOther = others.last;
        await sortIndex.moveToTail(
          draggedId: draggedTaskId,
          section: section,
          lastId: lastOther.id,
        );
      }
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 获取区域结束时间点（第一天的 23:59:59）
  DateTime _getSectionEndTime(TaskSection section) {
    return TaskSectionUtils.getSectionEndTime(section, now: _clock());
  }

  // ===== Inbox 拖拽方法 =====

  /// 处理 Inbox 任务在两个任务之间拖拽
  Future<void> handleInboxDragBetween(
    int draggedId,
    int beforeId,
    int afterId,
  ) async {
    final sortIndex = _sortIndex;
    if (sortIndex == null) return;

    // 邻居间隙过小则先对 Inbox 域做一次等差稀疏化
    final before = await _tasks.findById(beforeId);
    final after = await _tasks.findById(afterId);
    if (before != null && after != null) {
      if ((after.sortIndex - before.sortIndex).abs() < 2) {
        final inboxOrdered = await _tasks.watchInbox().first;
        // 使用统一的排序和重排方法
        await sortIndex.reorderTasksForInbox(tasks: inboxOrdered);
      }
    }

    await sortIndex.insertBetween(
      draggedId: draggedId,
      beforeId: beforeId,
      afterId: afterId,
    );
    debugPrint('InboxDnD between: $draggedId -> ($beforeId, $afterId)');
  }

  /// 处理 Inbox 任务拖拽到列表开头
  Future<void> handleInboxDragToFirst(int draggedId) async {
    final sortIndex = _sortIndex;
    if (sortIndex == null) return;

    // 获取当前排序后的第一个 inbox 任务(排除自身)
    final inboxTasks = await _tasks.watchInbox().first;
    final sortedTasks = inboxTasks.where((t) => t.id != draggedId).toList();
    // 使用统一的排序函数：sortIndex升序 → createdAt降序
    SortIndexService.sortTasksForInbox(sortedTasks);

    if (sortedTasks.isEmpty) {
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }

    // 如首元素与被拖拽元素间距过小，先稀疏化
    final dragged = await _tasks.findById(draggedId);
    if (dragged != null &&
        (sortedTasks.first.sortIndex - dragged.sortIndex).abs() < 2) {
      // 使用统一的排序和重排方法
      await sortIndex.reorderTasksForInbox(tasks: inboxTasks);
    }

    await sortIndex.moveToHead(
      draggedId: draggedId,
      section: TaskSection.later, // Inbox 使用 later 区域
      firstId: sortedTasks.first.id,
    );
    debugPrint('InboxDnD first: $draggedId -> head');
  }

  /// 处理 Inbox 任务拖拽到列表结尾
  Future<void> handleInboxDragToLast(int draggedId) async {
    final sortIndex = _sortIndex;
    if (sortIndex == null) return;

    // 获取当前排序后的最后一个 inbox 任务(排除自身)
    final inboxTasks = await _tasks.watchInbox().first;
    final sortedTasks = inboxTasks.where((t) => t.id != draggedId).toList();
    // 使用统一的排序函数：sortIndex升序 → createdAt降序
    SortIndexService.sortTasksForInbox(sortedTasks);

    if (sortedTasks.isEmpty) {
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }

    // 如尾元素与被拖拽元素间距过小，先稀疏化
    final dragged = await _tasks.findById(draggedId);
    if (dragged != null &&
        (sortedTasks.last.sortIndex - dragged.sortIndex).abs() < 2) {
      // 使用统一的排序和重排方法
      await sortIndex.reorderTasksForInbox(tasks: inboxTasks);
    }

    await sortIndex.moveToTail(
      draggedId: draggedId,
      section: TaskSection.later, // Inbox 使用 later 区域
      lastId: sortedTasks.last.id,
    );
    debugPrint('InboxDnD last: $draggedId -> tail');
  }
}

