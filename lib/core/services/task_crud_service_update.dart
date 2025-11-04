import 'package:flutter/foundation.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import 'metric_orchestrator.dart';
import 'tag_service.dart';
import 'task_crud_service_helpers.dart';

/// TaskCrudService 更新相关方法
/// 
/// 包含任务更新、标签更新等操作
class TaskCrudServiceUpdate {
  TaskCrudServiceUpdate({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    required TaskCrudServiceHelpers helpers,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _helpers = helpers,
       _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final TaskCrudServiceHelpers _helpers;
  final DateTime Function() _clock;

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
      dueForUpdate = TaskCrudServiceHelpers.normalizeDueDate(payload.dueAt!);
    }
    final dueChanged =
        dueForUpdate != null &&
            !TaskCrudServiceHelpers.isSameInstant(existing.dueAt, dueForUpdate);
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
      final allChildren = await _helpers.getAllDescendantTasks(taskId);
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
      final tagsChanged =
          !TaskCrudServiceHelpers.areTagsEqual(payload.tags!, existing.tags);
      if (tagsChanged) {
        final allChildren = await _helpers.getAllDescendantTasks(taskId);
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
      final allChildren = await _helpers.getAllDescendantTasks(taskId);
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
    final allChildren = await _helpers.getAllDescendantTasks(taskId);
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
}

