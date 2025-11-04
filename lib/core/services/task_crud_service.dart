import 'package:flutter/foundation.dart';
import '../../data/models/task.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/tasks/utils/hierarchy_utils.dart';
import '../constants/task_constants.dart';
import 'metric_orchestrator.dart';
import 'sort_index_service.dart';
import 'tag_service.dart';

/// 任务 CRUD 操作服务
/// 负责任务的创建、读取、更新和删除操作
class TaskCrudService {
  TaskCrudService({
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

  /// 递归获取所有后代任务（包括子任务的子任务）
  ///
  /// [taskId] 起始任务 ID
  /// 返回所有后代任务的列表（排除 project 和 milestone）
  Future<List<Task>> getAllDescendantTasks(int taskId) async {
    final result = <Task>[];
    final children = await _tasks.listChildren(taskId);

    // 只处理普通任务，排除 project 和 milestone
    final normalChildren = children
        .where((t) => !isProjectOrMilestone(t))
        .toList();

    for (final child in normalChildren) {
      result.add(child);
      // 递归获取子任务的子任务
      final grandchildren = await getAllDescendantTasks(child.id);
      result.addAll(grandchildren);
    }

    return result;
  }

  /// 在 Inbox 中创建任务
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

  /// 规划任务（设置截止日期和区域）
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
      // 找到当前首个"其它任务"（排除自己）
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
        final sortIndex = _sortIndex;
        if (sortIndex != null) {
          await sortIndex.moveToHead(
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

    // 如果任务有子任务，同步更新所有子任务的截止日期和状态
    // 子任务的状态会通过 batchUpdate 中的状态转换逻辑自动变为 pending
    final allChildren = await getAllDescendantTasks(taskId);
    if (allChildren.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[TaskCrudService.planTask] 同步子任务截止日期: taskId=$taskId, childrenCount=${allChildren.length}, newDueAt=$normalizedDue, section=$section',
        );
      }
      final updates = <int, TaskUpdate>{};
      for (final child in allChildren) {
        updates[child.id] = TaskUpdate(dueAt: normalizedDue);
      }
      await _tasks.batchUpdate(updates);
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 更新任务详情
  Future<void> updateDetails({
    required int taskId,
    required TaskUpdate payload,
  }) async {
    final existing = await _tasks.findById(taskId);
    if (existing == null) {
      if (kDebugMode) {
        debugPrint('[TaskCrudService.updateDetails] 任务不存在: taskId=$taskId');
      }
      return;
    }

    DateTime? dueForUpdate;
    if (payload.dueAt != null) {
      dueForUpdate = _normalizeDueDate(payload.dueAt!);
    }
    final dueChanged =
        dueForUpdate != null && !_isSameInstant(existing.dueAt, dueForUpdate);
    final now = _clock();
    List<TaskLogEntry>? updatedLogs;

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
        logs: updatedLogs,
        projectId: payload.projectId,
        milestoneId: payload.milestoneId,
        clearProject: payload.clearProject,
        clearMilestone: payload.clearMilestone,
      ),
    );

    // 在新架构下，里程碑是独立的模型，截止日期更新由 MilestoneService 处理
    // 这里不再需要检查 taskKind.milestone 并更新父项目

    // 如果截止日期变化，同步更新所有子任务的截止日期
    // 如果 dueChanged 为 true，则 dueForUpdate 一定不为 null
    if (dueChanged) {
      final allChildren = await getAllDescendantTasks(taskId);
      if (allChildren.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[TaskCrudService.updateDetails] 同步子任务截止日期: taskId=$taskId, childrenCount=${allChildren.length}, newDueAt=$dueForUpdate',
          );
        }
        final updates = <int, TaskUpdate>{};
        for (final child in allChildren) {
          updates[child.id] = TaskUpdate(dueAt: dueForUpdate);
        }
        await _tasks.batchUpdate(updates);
      }
    }

    // 如果标签变化，同步更新所有子任务的标签
    if (payload.tags != null) {
      // 检查标签是否真的发生变化
      final tagsChanged = !_areTagsEqual(payload.tags!, existing.tags);
      if (tagsChanged) {
        final allChildren = await getAllDescendantTasks(taskId);
        if (allChildren.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              '[TaskCrudService.updateDetails] 同步子任务标签: taskId=$taskId, childrenCount=${allChildren.length}, newTags=${payload.tags}',
            );
          }
          final updates = <int, TaskUpdate>{};
          for (final child in allChildren) {
            updates[child.id] = TaskUpdate(tags: payload.tags);
          }
          await _tasks.batchUpdate(updates);
        }
      }
    }

    // 如果项目/里程碑变化（projectId/milestoneId），同步更新所有子任务的项目/里程碑关联
    final projectIdChanged =
        (payload.projectId != existing.projectId) ||
        (payload.clearProject == true && existing.projectId != null);
    final milestoneIdChanged =
        (payload.milestoneId != existing.milestoneId) ||
        (payload.clearMilestone == true && existing.milestoneId != null);

    if (projectIdChanged || milestoneIdChanged) {
      final allChildren = await getAllDescendantTasks(taskId);
      if (allChildren.isNotEmpty) {
        final newProjectId = payload.clearProject == true
            ? null
            : (payload.projectId ?? existing.projectId);
        final newMilestoneId = payload.clearMilestone == true
            ? null
            : (payload.milestoneId ?? existing.milestoneId);

        if (kDebugMode) {
          debugPrint(
            '[TaskCrudService.updateDetails] 同步子任务项目/里程碑: taskId=$taskId, childrenCount=${allChildren.length}, newProjectId=$newProjectId, newMilestoneId=$newMilestoneId',
          );
        }

        final updates = <int, TaskUpdate>{};
        for (final child in allChildren) {
          updates[child.id] = TaskUpdate(
            projectId: newProjectId,
            milestoneId: newMilestoneId,
            clearProject: payload.clearProject,
            clearMilestone: payload.clearMilestone,
          );
        }
        await _tasks.batchUpdate(updates);
      }
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 比较两个标签列表是否相等
  bool _areTagsEqual(List<String> tags1, List<String> tags2) {
    if (tags1.length != tags2.length) {
      return false;
    }
    final sorted1 = List<String>.from(tags1)..sort();
    final sorted2 = List<String>.from(tags2)..sort();
    return sorted1.toString() == sorted2.toString();
  }

  /// 更新任务标签
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

    // 同步更新所有子任务的标签
    final allChildren = await getAllDescendantTasks(taskId);
    if (allChildren.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[TaskCrudService.updateTags] 同步子任务标签: taskId=$taskId, childrenCount=${allChildren.length}, newTags=$normalized',
        );
      }
      final updates = <int, TaskUpdate>{};
      for (final child in allChildren) {
        updates[child.id] = TaskUpdate(tags: normalized);
      }
      await _tasks.batchUpdate(updates);
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 清空回收站：批量永久删除所有回收站任务
  /// 返回删除的任务数量
  Future<int> clearTrash() async {
    final count = await _tasks.clearAllTrashedTasks();
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return count;
  }

  /// 标准化截止日期为当天的 23:59:59
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

  /// 比较两个时间点是否相同
  bool _isSameInstant(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null) {
      return false;
    }
    return a.millisecondsSinceEpoch == b.millisecondsSinceEpoch;
  }
}

