import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/tag_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
import '../../presentation/tasks/utils/sort_index_calculator.dart';
import 'metric_orchestrator.dart';
import '../constants/task_constants.dart';
import 'sort_index_service.dart';
import 'task_hierarchy_service.dart';
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
    if (dragged != null && (sortedTasks.first.sortIndex - dragged.sortIndex).abs() < 2) {
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
    if (dragged != null && (sortedTasks.last.sortIndex - dragged.sortIndex).abs() < 2) {
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

  /// 处理子任务向左拖拽升级为根任务
  ///
  /// 当子任务向左拖拽超过指定阈值（30px）且垂直位移较小时，
  /// 将其升级为根任务，排序在原父任务/祖任务之后。
  ///
  /// [taskId] 被拖拽的任务 ID
  /// [taskHierarchyService] 任务层级服务，用于执行 moveToParent 操作
  /// [horizontalOffset] 水平位移（负值表示向左）
  /// [verticalOffset] 垂直位移
  /// [leftDragThreshold] 向左拖拽的阈值（默认 -30.0）
  /// [verticalThreshold] 垂直位移的最大允许值（默认 50.0）
  ///
  /// 返回 true 如果成功执行了升级操作，false 如果条件不满足或操作失败
  Future<bool> handleLeftDragPromotion(
    int taskId,
    TaskHierarchyService taskHierarchyService, {
    required double? horizontalOffset,
    required double? verticalOffset,
    double leftDragThreshold = -30.0,
    double verticalThreshold = 50.0,
  }) async {
    // 检查条件：水平位移必须小于阈值，垂直位移必须小于阈值
    if (horizontalOffset == null || verticalOffset == null) {
      return false;
    }

    if (horizontalOffset >= leftDragThreshold) {
      // 未达到向左拖拽阈值
      return false;
    }

    if (verticalOffset.abs() >= verticalThreshold) {
      // 垂直位移过大，不是向左拖拽升级动作
      return false;
    }

    // 获取任务信息
    final task = await _tasks.findById(taskId);
    if (task == null || task.parentId == null) {
      // 任务不存在或不是子任务
      return false;
    }

    // 使用复用的异步方法计算任务的层级（level），直接通过 repository 查询
    final taskDepth = await calculateHierarchyDepth(task, _tasks);
    final taskLevel = taskDepth + 1; // level 1/2/3

    if (taskLevel < 2) {
      // 已经是根任务（level 1），不需要升级
      return false;
    }

    int? targetParentId;
    Task? referenceTask; // 用于计算 sortIndex 的参考任务

    if (taskLevel == 2) {
      // 2级任务：升级为根任务（level 1）
      targetParentId = null;
      // 找到父任务（根任务）作为参考
      final parent = await _tasks.findById(task.parentId!);
      if (parent == null) {
        return false;
      }
      referenceTask = parent;
    } else if (taskLevel == 3) {
      // 3级任务：升级为2级任务，成为其祖父任务的子任务
      final ancestors = await buildAncestorChain(taskId, _tasks);
      if (ancestors.isEmpty) {
        // 无法找到祖先，应该不会发生，但安全起见返回 false
        return false;
      }
      // ancestors 列表的顺序是：从最近的父任务到最远的祖先（已反转）
      // 对于 level 3 任务：ancestors[0] 是父任务（level 2），ancestors[ancestors.length - 1] 是祖父任务（level 1/根任务）
      // 我们需要祖父任务作为新的父任务
      if (ancestors.length < 2) {
        // 祖先链不足，无法确定祖父任务
        return false;
      }
      final grandparent = ancestors[ancestors.length - 1]; // 最远的祖先（根任务）
      targetParentId = grandparent.id;
      referenceTask = grandparent;
    } else {
      // 不支持超过3级的任务（理论上不应该发生）
      return false;
    }

    // referenceTask 在这里肯定不为 null（因为前面的分支都有返回值或赋值）

    // 计算新的 sortIndex：排在参考任务之后
    final newSortIndex = SortIndexCalculator.insertAfter(referenceTask.sortIndex);

    if (kDebugMode) {
      debugPrint(
        '[DnD] {event: leftDragPromotion, taskId: $taskId, taskLevel: $taskLevel, targetParentId: $targetParentId, referenceTaskId: ${referenceTask.id}, newSortIndex: $newSortIndex, horizontalOffset: $horizontalOffset, verticalOffset: $verticalOffset}',
      );
    }

    try {
      // 执行升级操作
      await taskHierarchyService.moveToParent(
        taskId: taskId,
        parentId: targetParentId,
        sortIndex: newSortIndex,
        clearParent: targetParentId == null,
      );

      // 批量重排所有 inbox 任务的 sortIndex
      final sortIndex = _sortIndex;
      if (sortIndex != null) {
        final allInboxTasks = await _tasks.watchInbox().first;
        await sortIndex.reorderTasksForInbox(tasks: allInboxTasks);
      }

      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: leftDragPromotion:success, taskId: $taskId}',
        );
      }

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '[DnD] {event: leftDragPromotion:error, taskId: $taskId, error: $e}',
        );
        debugPrint('$stackTrace');
      }
      return false;
    }
  }
}
