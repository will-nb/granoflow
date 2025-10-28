import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/tag_repository.dart';
import 'metric_orchestrator.dart';
import '../constants/task_constants.dart';
import 'sort_index_service.dart';

class TaskService {
  TaskService({
    required TaskRepository taskRepository,
    required TagRepository tagRepository,
    required MetricOrchestrator metricOrchestrator,
    SortIndexService? sortIndexService,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _tags = tagRepository,
       _metricOrchestrator = metricOrchestrator,
       _sortIndex = sortIndexService,
       _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final TagRepository _tags;
  final MetricOrchestrator _metricOrchestrator;
  final SortIndexService? _sortIndex;
  final DateTime Function() _clock;

  Future<Task> captureInboxTask({
    required String title,
    List<String> tags = const <String>[],
  }) async {
    final draft = TaskDraft(
      title: title,
      status: TaskStatus.inbox,
      tags: tags,
      allowInstantComplete: false,
      sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
    );
    final task = await _tasks.createTask(draft);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return task;
  }

  Future<void> planTask({
    required int taskId,
    required DateTime dueDateLocal,
    required TaskSection section,
  }) async {
    final normalizedDue = _normalizeDueDate(dueDateLocal);
    await _tasks.moveTask(
      taskId: taskId,
      targetParentId: null,
      targetSection: section,
      sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
      dueAt: normalizedDue,
    );
    // 规则：新任务插入到本区域最前
    try {
      final tasksInSection = await _tasks.listSectionTasks(section);
      // 找到当前首个“其它任务”（排除自己）
      final firstOther = tasksInSection.firstWhere(
        (t) => t.id != taskId,
        orElse: () => Task(
          id: -1,
          taskId: '',
          title: '',
          status: TaskStatus.pending,
          createdAt: DateTime(1970, 1, 1),
          updatedAt: DateTime(1970, 1, 1),
          sortIndex: 0,
        ),
      );
      if (firstOther.id == -1) {
        // 区域为空或只有自己 → 赋默认HEAD
        await _tasks.updateTask(taskId, const TaskUpdate(sortIndex: 1024));
      } else {
        if (_sortIndex != null) {
          await _sortIndex.moveToHead(
            draggedId: taskId,
            section: section,
            firstId: firstOther.id,
          );
        } else {
          // 退化实现：直接写 head = first.sortIndex - STEP
          final newIndex = (firstOther.sortIndex - 1024).toDouble();
          await _tasks.updateTask(taskId, TaskUpdate(sortIndex: newIndex));
        }
      }
    } catch (_) {
      // 忽略排序错误，保证主流程
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> updateDetails({
    required int taskId,
    required TaskUpdate payload,
  }) async {
    await _tasks.updateTask(taskId, payload);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> updateTags({
    required int taskId,
    String? contextTag,
    String? priorityTag,
  }) async {
    final task = await _tasks.findById(taskId);
    if (task == null) {
      return;
    }
    final normalized = task.tags
        .where((tag) => !_isContextTag(tag) && !_isPriorityTag(tag))
        .toList(growable: true);
    if (contextTag != null && contextTag.isNotEmpty) {
      normalized.add(contextTag);
    }
    if (priorityTag != null && priorityTag.isNotEmpty) {
      normalized.add(priorityTag);
    }
    await _tasks.updateTask(taskId, TaskUpdate(tags: normalized));
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> markInProgress(int taskId) async {
    await _tasks.markStatus(taskId: taskId, status: TaskStatus.doing);
  }

  Future<void> markCompleted({
    required int taskId,
    bool autoCompleteParent = true,
  }) async {
    final task = await _tasks.findById(taskId);
    if (task == null) {
      return;
    }
    if (!task.canEditStructure && !task.allowInstantComplete) {
      throw StateError('Task is locked and cannot be completed directly.');
    }
    await _tasks.updateTask(
      taskId,
      TaskUpdate(status: TaskStatus.completedActive, endedAt: _clock()),
    );
    if (autoCompleteParent && task.parentId != null) {
      final siblings = await _tasks.listChildren(task.parentId!);
      final allCompleted = siblings.every(
        (sibling) => sibling.status == TaskStatus.completedActive,
      );
      if (allCompleted) {
        await _tasks.updateTask(
          task.parentId!,
          TaskUpdate(status: TaskStatus.completedActive, endedAt: _clock()),
        );
      }
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> archive(int taskId) async {
    await _tasks.archiveTask(taskId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> softDelete(int taskId) async {
    final task = await _tasks.findById(taskId);
    if (task != null && task.templateLockCount > 0) {
      throw StateError('Task is locked by templates; remove template first.');
    }
    await _tasks.softDelete(taskId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<List<Tag>> listTagsByKind(TagKind kind) => _tags.listByKind(kind);

  Future<List<Task>> searchTasksByTitle(
    String query, {
    TaskStatus? status,
    int limit = 20,
  }) {
    if (query.trim().isEmpty) {
      return Future.value(const <Task>[]);
    }
    return _tasks.searchByTitle(
      query,
      status: status,
      limit: limit,
    );
  }

  DateTime _normalizeDueDate(DateTime localDate) {
    final converted = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
    return converted;
  }

  bool _isContextTag(String tag) => tag.startsWith('@');
  bool _isPriorityTag(String tag) => tag.startsWith('#');

  /// 处理拖拽到任务间（调整sortIndex）
  Future<void> handleDragBetweenTasks(int draggedTaskId, int beforeTaskId, int afterTaskId) async {
    debugPrint('拖拽排序Between: task=$draggedTaskId between $beforeTaskId/$afterTaskId');
    if (_sortIndex == null) return;
    await _sortIndex.insertBetween(
      draggedId: draggedTaskId,
      beforeId: beforeTaskId,
      afterId: afterTaskId,
    );
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 处理拖拽到区域首位
  Future<void> handleDragToSectionFirst(int draggedTaskId, TaskSection section) async {
    final sectionMidTime = _getSectionMidTime(section);
    debugPrint('拖拽到区域首位: task=$draggedTaskId, section=$section');
    await _tasks.updateTask(
      draggedTaskId,
      TaskUpdate(dueAt: sectionMidTime),
    );
    // 找到区域首元素（排除自身），调用 moveToHead
    final tasks = await _tasks.listSectionTasks(section);
    final others = tasks.where((t) => t.id != draggedTaskId).toList(growable: false);
    if (others.isEmpty) {
      if (_sortIndex != null) {
        await _tasks.updateTask(draggedTaskId, const TaskUpdate(sortIndex: 1024));
      }
    } else {
      final first = others.first;
      if (_sortIndex != null) {
        await _sortIndex.moveToHead(
          draggedId: draggedTaskId,
          section: section,
          firstId: first.id,
        );
      }
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 处理拖拽到区域末位
  Future<void> handleDragToSectionLast(int draggedTaskId, TaskSection section) async {
    final sectionMidTime = _getSectionMidTime(section);
    debugPrint('拖拽到区域末位: task=$draggedTaskId, section=$section');
    await _tasks.updateTask(
      draggedTaskId,
      TaskUpdate(dueAt: sectionMidTime),
    );
    final tasks = await _tasks.listSectionTasks(section);
    if (_sortIndex != null) {
      final others = tasks.where((t) => t.id != draggedTaskId).toList(growable: false);
      if (others.isEmpty) {
        await _tasks.updateTask(draggedTaskId, const TaskUpdate(sortIndex: 1024));
      } else {
        final lastOther = others.last;
        await _sortIndex.moveToTail(
          draggedId: draggedTaskId,
          section: section,
          lastId: lastOther.id,
        );
      }
    }
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 获取区域中间时间点（12:00:00）
  DateTime _getSectionMidTime(TaskSection section) {
    final now = _clock();
    switch (section) {
      case TaskSection.overdue:
        return DateTime(now.year, now.month, now.day - 1, 12, 0, 0);
      case TaskSection.today:
        return DateTime(now.year, now.month, now.day, 12, 0, 0);
      case TaskSection.tomorrow:
        return DateTime(now.year, now.month, now.day + 1, 12, 0, 0);
      case TaskSection.thisWeek:
        final weekStart = _getThisWeekStart(now);
        return DateTime(weekStart.year, weekStart.month, weekStart.day + 3, 12, 0, 0);
      case TaskSection.thisMonth:
        return DateTime(now.year, now.month, 15, 12, 0, 0);
      case TaskSection.later:
        return DateTime(now.year + 1, 1, 1, 12, 0, 0);
      default:
        return now;
    }
  }

  /// 获取本周开始时间
  DateTime _getThisWeekStart(DateTime now) {
    final daysFromMonday = (now.weekday - DateTime.monday) % 7;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  // ===== Inbox 拖拽方法 =====

  /// 处理 Inbox 任务在两个任务之间拖拽
  Future<void> handleInboxDragBetween(int draggedId, int beforeId, int afterId) async {
    if (_sortIndex == null) return;

    // 邻居间隙过小则先对 Inbox 域做一次等差稀疏化
    final before = await _tasks.findById(beforeId);
    final after = await _tasks.findById(afterId);
    if (before != null && after != null) {
      if ((after.sortIndex - before.sortIndex).abs() < 2) {
        final inboxOrdered = await _tasks.watchInbox().first;
        await _sortIndex!.reorderIds(
          orderedIds: inboxOrdered.map((t) => t.id).toList(),
        );
      }
    }

    await _sortIndex!.insertBetween(
      draggedId: draggedId,
      beforeId: beforeId,
      afterId: afterId,
    );
    debugPrint('InboxDnD between: $draggedId -> ($beforeId, $afterId)');
  }

  /// 处理 Inbox 任务拖拽到列表开头
  Future<void> handleInboxDragToFirst(int draggedId) async {
    if (_sortIndex == null) return;
    
    // 获取当前排序后的第一个 inbox 任务(排除自身)
    final inboxTasks = await _tasks.watchInbox().first;
    final sortedTasks = inboxTasks.where((t) => t.id != draggedId).toList()
      ..sort((a, b) {
        final cmp = a.sortIndex.compareTo(b.sortIndex);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });

    if (sortedTasks.isEmpty) {
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }

    // 如首元素与被拖拽元素间距过小，先稀疏化
    final dragged = await _tasks.findById(draggedId);
    if (dragged != null && (sortedTasks.first.sortIndex - dragged.sortIndex).abs() < 2) {
      await _sortIndex!.reorderIds(
        orderedIds: inboxTasks.map((t) => t.id).toList(),
      );
    }

    await _sortIndex!.moveToHead(
      draggedId: draggedId,
      section: TaskSection.later, // Inbox 使用 later 区域
      firstId: sortedTasks.first.id,
    );
    debugPrint('InboxDnD first: $draggedId -> head');
  }

  /// 处理 Inbox 任务拖拽到列表结尾
  Future<void> handleInboxDragToLast(int draggedId) async {
    if (_sortIndex == null) return;
    
    // 获取当前排序后的最后一个 inbox 任务(排除自身)
    final inboxTasks = await _tasks.watchInbox().first;
    final sortedTasks = inboxTasks.where((t) => t.id != draggedId).toList()
      ..sort((a, b) {
        final cmp = a.sortIndex.compareTo(b.sortIndex);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });

    if (sortedTasks.isEmpty) {
      await _tasks.updateTask(draggedId, const TaskUpdate(sortIndex: 1024));
      return;
    }

    // 如尾元素与被拖拽元素间距过小，先稀疏化
    final dragged = await _tasks.findById(draggedId);
    if (dragged != null && (sortedTasks.last.sortIndex - dragged.sortIndex).abs() < 2) {
      await _sortIndex!.reorderIds(
        orderedIds: inboxTasks.map((t) => t.id).toList(),
      );
    }

    await _sortIndex!.moveToTail(
      draggedId: draggedId,
      section: TaskSection.later, // Inbox 使用 later 区域
      lastId: sortedTasks.last.id,
    );
    debugPrint('InboxDnD last: $draggedId -> tail');
  }
}


