import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/tag_repository.dart';
import 'metric_orchestrator.dart';
import '../constants/task_constants.dart';
import 'sort_index_service.dart';
import '../utils/task_section_utils.dart';
import 'tag_service.dart';

class ProjectMilestoneBlueprint {
  const ProjectMilestoneBlueprint({
    required this.title,
    this.dueDate,
    this.tags = const <String>[],
    this.description,
  });

  final String title;
  final DateTime? dueDate;
  final List<String> tags;
  final String? description;
}

class ProjectBlueprint {
  const ProjectBlueprint({
    required this.title,
    required this.dueDate,
    this.description,
    this.tags = const <String>[],
    this.milestones = const <ProjectMilestoneBlueprint>[],
  });

  final String title;
  final DateTime dueDate;
  final String? description;
  final List<String> tags;
  final List<ProjectMilestoneBlueprint> milestones;
}

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
    final existing = await _tasks.findById(taskId);
    if (existing == null) {
      if (kDebugMode) {
        debugPrint('[TaskService.updateDetails] 任务不存在: taskId=$taskId');
      }
      return;
    }

    if (kDebugMode) {
      final oldSection = TaskSectionUtils.getSectionForDate(existing.dueAt, now: _clock());
      debugPrint(
        '[TaskService.updateDetails] 开始更新: taskId=$taskId, oldDueAt=${existing.dueAt}, oldSortIndex=${existing.sortIndex}, oldStatus=${existing.status}, oldTaskKind=${existing.taskKind}, oldSection=$oldSection',
      );
    }

    DateTime? dueForUpdate;
    if (payload.dueAt != null) {
      dueForUpdate = _normalizeDueDate(payload.dueAt!);
    }
    final dueChanged = dueForUpdate != null &&
        !_isSameInstant(existing.dueAt, dueForUpdate);
    final now = _clock();
    List<TaskLogEntry>? updatedLogs;

    if (kDebugMode && dueChanged) {
      final newSection = TaskSectionUtils.getSectionForDate(dueForUpdate, now: now);
      final oldSection = TaskSectionUtils.getSectionForDate(existing.dueAt, now: now);
      debugPrint(
        '[TaskService.updateDetails] 日期变更: taskId=$taskId, oldDueAt=${existing.dueAt} (section=$oldSection), newDueAt=$dueForUpdate (section=$newSection)',
      );
    }

    void ensureLogBuffer() {
      updatedLogs ??= existing.logs.toList(growable: true);
    }

    if (payload.logs != null && payload.logs!.isNotEmpty) {
      ensureLogBuffer();
      updatedLogs!.addAll(payload.logs!);
    }

    if (dueChanged) {
      final newDue = dueForUpdate;
      ensureLogBuffer();
      updatedLogs!.add(
        TaskLogEntry(
          timestamp: now,
          action: existing.dueAt == null ? 'deadline_set' : 'deadline_updated',
          previous: existing.dueAt?.toIso8601String(),
          next: newDue.toIso8601String(),
        ),
      );
    }

    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        title: payload.title,
        status: payload.status,
        dueAt: dueForUpdate ?? payload.dueAt,
        startedAt: payload.startedAt,
        endedAt: payload.endedAt,
        parentId: payload.parentId,
        sortIndex: payload.sortIndex,
        tags: payload.tags,
        templateLockDelta: payload.templateLockDelta,
        allowInstantComplete: payload.allowInstantComplete,
        description: payload.description ?? existing.description,
        taskKind: payload.taskKind,
        logs: updatedLogs,
      ),
    );

    if (kDebugMode) {
      final updated = await _tasks.findById(taskId);
      if (updated != null) {
        final newSection = TaskSectionUtils.getSectionForDate(updated.dueAt, now: now);
        debugPrint(
          '[TaskService.updateDetails] 更新完成: taskId=$taskId, newDueAt=${updated.dueAt}, newSortIndex=${updated.sortIndex}, newStatus=${updated.status}, newTaskKind=${updated.taskKind}, newSection=$newSection',
        );
      }
    }

    if (dueChanged &&
        existing.taskKind == TaskKind.milestone &&
        existing.parentId != null) {
      final parent = await _tasks.findById(existing.parentId!);
      if (parent != null) {
        final newDue = dueForUpdate;
        final parentNeedsUpdate = parent.dueAt == null ||
            newDue.isAfter(parent.dueAt!);
        if (parentNeedsUpdate) {
          final parentLogs = parent.logs.toList(growable: true)
            ..add(
              TaskLogEntry(
                timestamp: now,
                action: parent.dueAt == null
                    ? 'deadline_set'
                    : 'deadline_updated',
                previous: parent.dueAt?.toIso8601String(),
                next: newDue.toIso8601String(),
              ),
            );
          await _tasks.updateTask(
            parent.id,
            TaskUpdate(
              dueAt: newDue,
              logs: parentLogs,
            ),
          );
        }
      }
    }

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
    // 过滤掉上下文标签和优先级标签（使用 TagService 判断类型）
    final normalized = task.tags
        .where((tag) {
          final kind = TagService.getKind(tag);
          return kind != TagKind.context && 
                 kind != TagKind.urgency && 
                 kind != TagKind.importance && 
                 kind != TagKind.execution;
        })
        .toList(growable: true);
    if (contextTag != null && contextTag.isNotEmpty) {
      normalized.add(TagService.normalizeSlug(contextTag));
    }
    if (priorityTag != null && priorityTag.isNotEmpty) {
      normalized.add(TagService.normalizeSlug(priorityTag));
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

  Stream<List<Task>> watchProjects() => _tasks.watchProjects();

  Stream<List<Task>> watchQuickTasks() => _tasks.watchQuickTasks();

  Stream<List<Task>> watchMilestones(int projectId) => _tasks.watchMilestones(projectId);

  Future<Task> createProject(ProjectBlueprint blueprint) async {
    final dueAt = _normalizeDueDate(blueprint.dueDate);
    final now = _clock();
    final projectTags = _uniqueTags(blueprint.tags);
    final projectLogs = <TaskLogEntry>[
      TaskLogEntry(
        timestamp: now,
        action: 'deadline_set',
        next: dueAt.toIso8601String(),
      ),
    ];

    final project = await _tasks.createTask(
      TaskDraft(
        title: blueprint.title,
        status: TaskStatus.pending,
        dueAt: dueAt,
        sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
        tags: projectTags,
        allowInstantComplete: false,
        description: blueprint.description,
        taskKind: TaskKind.project,
        logs: projectLogs,
      ),
    );

    for (final milestone in blueprint.milestones) {
      final milestoneDue = milestone.dueDate != null
          ? _normalizeDueDate(milestone.dueDate!)
          : null;
      final milestoneLogs = <TaskLogEntry>[];
      if (milestoneDue != null) {
        milestoneLogs.add(
          TaskLogEntry(
            timestamp: now,
            action: 'deadline_set',
            next: milestoneDue.toIso8601String(),
          ),
        );
      }
      await _tasks.createTask(
        TaskDraft(
          title: milestone.title,
          status: TaskStatus.pending,
          parentId: project.id,
          dueAt: milestoneDue,
          sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
          tags: _uniqueTags(milestone.tags),
          allowInstantComplete: false,
          description: milestone.description,
          taskKind: TaskKind.milestone,
          logs: milestoneLogs,
        ),
      );
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return project;
  }

  Future<void> convertToProject(int taskId) async {
    final task = await _tasks.findById(taskId);
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }
    if (task.taskKind == TaskKind.project) {
      return;
    }

    final now = _clock();
    final projectLogs = task.logs.toList(growable: true)
      ..add(
        TaskLogEntry(
          timestamp: now,
          action: 'converted_to_project',
        ),
      );
    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        taskKind: TaskKind.project,
        logs: projectLogs,
      ),
    );

    final children = await _tasks.listChildren(taskId);
    for (final child in children) {
      if (child.taskKind == TaskKind.regular) {
        final childLogs = child.logs.toList(growable: true)
          ..add(
            TaskLogEntry(
              timestamp: now,
              action: 'converted_to_milestone',
            ),
          );
        await _tasks.updateTask(
          child.id,
          TaskUpdate(
            taskKind: TaskKind.milestone,
            logs: childLogs,
          ),
        );
      }
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> snoozeProject(int projectId) async {
    final project = await _tasks.findById(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }
    if (project.taskKind != TaskKind.project) {
      throw StateError('Task $projectId is not a project');
    }

    final now = _clock();
    final baseDue = project.dueAt ?? _normalizeDueDate(now);
    final newDue = _addOneYear(baseDue);
    final logs = project.logs.toList(growable: true)
      ..add(
        TaskLogEntry(
          timestamp: now,
          action: 'deadline_snoozed',
          previous: baseDue.toIso8601String(),
          next: newDue.toIso8601String(),
        ),
      );

    await _tasks.updateTask(
      projectId,
      TaskUpdate(
        dueAt: newDue,
        logs: logs,
      ),
    );

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

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

  DateTime _addOneYear(DateTime date) {
    final targetYear = date.year + 1;
    final isLeapTarget = _isLeapYear(targetYear);
    final isLeapDay = date.month == DateTime.february && date.day == 29;
    final adjustedDay = isLeapDay && !isLeapTarget ? 28 : date.day;
    return DateTime(
      targetYear,
      date.month,
      adjustedDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  bool _isLeapYear(int year) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    return year % 400 == 0;
  }


  bool _isSameInstant(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.millisecondsSinceEpoch == b.millisecondsSinceEpoch;
  }

  List<String> _uniqueTags(Iterable<String> tags) {
    final result = <String>[];
    for (final tag in tags) {
      if (tag.isEmpty) continue;
      if (result.contains(tag)) continue;
      result.add(tag);
    }
    return result;
  }

  /// 处理拖拽到任务间（调整sortIndex，支持跨区域）
  Future<void> handleDragBetweenTasks(int draggedTaskId, int beforeTaskId, int afterTaskId) async {
    debugPrint('拖拽排序Between: task=$draggedTaskId between $beforeTaskId/$afterTaskId');
    
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
      debugPrint('跨区域拖拽: $currentSection -> $targetSection, 更新 dueAt 为 $sectionEndTime');
      await _tasks.updateTask(
        draggedTaskId,
        TaskUpdate(dueAt: sectionEndTime),
      );
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
  Future<void> handleDragToSectionFirst(int draggedTaskId, TaskSection section) async {
    final sectionEndTime = _getSectionEndTime(section);
    debugPrint('拖拽到区域首位: task=$draggedTaskId, section=$section');
    await _tasks.updateTask(
      draggedTaskId,
      TaskUpdate(dueAt: sectionEndTime),
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
  Future<void> handleDragToSectionLast(int draggedTaskId, TaskSection section) async {
    final sectionEndTime = _getSectionEndTime(section);
    debugPrint('拖拽到区域末位: task=$draggedTaskId, section=$section');
    await _tasks.updateTask(
      draggedTaskId,
      TaskUpdate(dueAt: sectionEndTime),
    );
    final tasks = await _tasks.listSectionTasks(section);
    final sortIndex = _sortIndex;
    if (sortIndex != null) {
      final others = tasks.where((t) => t.id != draggedTaskId).toList(growable: false);
      if (others.isEmpty) {
        await _tasks.updateTask(draggedTaskId, const TaskUpdate(sortIndex: 1024));
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
  Future<void> handleInboxDragBetween(int draggedId, int beforeId, int afterId) async {
    final sortIndex = _sortIndex;
    if (sortIndex == null) return;

    // 邻居间隙过小则先对 Inbox 域做一次等差稀疏化
    final before = await _tasks.findById(beforeId);
    final after = await _tasks.findById(afterId);
    if (before != null && after != null) {
      if ((after.sortIndex - before.sortIndex).abs() < 2) {
        final inboxOrdered = await _tasks.watchInbox().first;
        await sortIndex.reorderIds(
          orderedIds: inboxOrdered.map((t) => t.id).toList(),
        );
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
      await sortIndex.reorderIds(
        orderedIds: inboxTasks.map((t) => t.id).toList(),
      );
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
      await sortIndex.reorderIds(
        orderedIds: inboxTasks.map((t) => t.id).toList(),
      );
    }

    await sortIndex.moveToTail(
      draggedId: draggedId,
      section: TaskSection.later, // Inbox 使用 later 区域
      lastId: sortedTasks.last.id,
    );
    debugPrint('InboxDnD last: $draggedId -> tail');
  }
}
