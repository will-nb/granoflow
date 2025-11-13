import 'package:flutter/foundation.dart';
import '../../data/models/tag.dart';
import '../../data/models/task.dart';
import '../../data/repositories/task_repository.dart';
import 'metric_orchestrator.dart';
import 'milestone_service.dart';
import 'project_service.dart';
import 'tag_service.dart';
import 'task_crud_service_helpers.dart';

/// TaskCrudService 更新相关方法
/// 
/// 包含任务更新、标签更新等操作
class TaskCrudServiceUpdate {
  TaskCrudServiceUpdate({
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    required MilestoneService milestoneService,
    ProjectService? projectService,
    required TaskCrudServiceHelpers helpers,
    DateTime Function()? clock,
  }) : _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _milestoneService = milestoneService,
       _projectService = projectService,
       _helpers = helpers,
       _clock = clock ?? DateTime.now;

  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final MilestoneService _milestoneService;
  final ProjectService? _projectService;
  final TaskCrudServiceHelpers _helpers;
  final DateTime Function() _clock;

  /// 更新任务详情
  Future<void> updateDetails({
    required String taskId,
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
    final now = _clock();
    List<TaskLogEntry>? updatedLogs;

    void ensureLogBuffer() {
      updatedLogs ??= existing.logs.toList(growable: true);
    }

    if (payload.logs != null && payload.logs!.isNotEmpty) {
      ensureLogBuffer();
      updatedLogs!.addAll(payload.logs!);
    }

    // 自动绑定逻辑：收集箱任务分配里程碑时自动设置截止日期和状态转换
    // 需要在 dueChanged 检查之前执行，以便正确计算 dueChanged
    final milestoneIdChanged = (payload.milestoneId != existing.milestoneId) ||
        (payload.clearMilestone == true && existing.milestoneId != null);
    
    if (milestoneIdChanged && payload.milestoneId != null) {
      try {
        final milestone = await _milestoneService.findById(payload.milestoneId!);
        if (milestone == null) {
          if (kDebugMode) {
            debugPrint(
              '[TaskCrudService.updateDetails] {event: autoBinding:milestoneNotFound, taskId: $taskId, milestoneId: ${payload.milestoneId}}',
            );
          }
        } else {
          // 如果任务当前状态为 inbox 且里程碑有截止日期
          if (existing.status == TaskStatus.inbox && milestone.dueAt != null) {
            // 如果任务当前没有截止日期且用户未手动设置截止日期
            if (existing.dueAt == null && payload.dueAt == null) {
              // 自动设置任务的截止日期为里程碑的截止日期
              final milestoneDueAt = milestone.dueAt!;
              dueForUpdate = TaskCrudServiceHelpers.normalizeDueDate(milestoneDueAt);
              
              // 在任务日志中记录此次自动设置
              ensureLogBuffer();
              updatedLogs!.add(
                TaskLogEntry(
                  timestamp: now,
                  action: 'deadline_set',
                  next: dueForUpdate.toIso8601String(),
                ),
              );
              
              if (kDebugMode) {
                debugPrint(
                  '[TaskCrudService.updateDetails] {event: autoBinding:deadlineSet, taskId: $taskId, milestoneId: ${payload.milestoneId}, dueAt: $dueForUpdate}',
                );
              }
            }
            
            // 如果截止日期被设置（自动或手动），触发现有的状态转换逻辑
            // 这个逻辑在下面的 finalStatus 计算中处理
            if (dueForUpdate != null || payload.dueAt != null) {
              if (kDebugMode) {
                debugPrint(
                  '[TaskCrudService.updateDetails] {event: autoBinding:statusChanged, taskId: $taskId, from: inbox, to: pending}',
                );
              }
            }
          }
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '[TaskCrudService.updateDetails] {event: autoBinding:failed, taskId: $taskId, milestoneId: ${payload.milestoneId}, reason: exception, error: $e, stackTrace: $stackTrace}',
          );
        }
        // 任务仍然分配里程碑，但不自动设置截止日期和状态
        // 继续执行其他更新操作，不中断整个更新流程
      }
    }

    // 计算 dueChanged（考虑自动绑定逻辑设置的 dueForUpdate）
    final dueChanged = dueForUpdate != null &&
        !TaskCrudServiceHelpers.isSameInstant(existing.dueAt, dueForUpdate);

    if (dueChanged) {
      // dueChanged is true only when dueForUpdate != null
      final newDue = dueForUpdate;
      // 只有在不是自动绑定设置的情况下才添加日志（自动绑定已经添加了日志）
      if (payload.dueAt != null) {
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
    }

    // 计算最终的 dueAt 值（考虑自动绑定逻辑设置的 dueForUpdate）
    final finalDueAt = dueForUpdate ?? payload.dueAt ?? existing.dueAt;
    
    // 底层规则：如果任务有截止日期，状态一定不是 inbox
    // 如果最终有截止日期，且当前状态是 inbox，且 payload 没有明确指定状态，则自动改为 pending
    final finalStatus = payload.status ??
        (finalDueAt != null && existing.status == TaskStatus.inbox
            ? TaskStatus.pending
            : null);

    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        title: payload.title,
        status: finalStatus,
        dueAt: dueForUpdate ?? payload.dueAt,
        startedAt: payload.startedAt,
        endedAt: payload.endedAt,
        // 层级功能已移除，不再处理 parentId
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

    // 层级功能已移除，不再需要同步子任务截止日期

    // 层级功能已移除，不再需要同步子任务标签

    // 层级功能已移除，不再需要同步子任务项目/里程碑关联

    // 如果任务属于项目但没有里程碑，确保任务有里程碑
    final finalProjectId = payload.projectId ?? existing.projectId;
    if (finalProjectId != null && _projectService != null) {
      // 检查任务是否有里程碑
      final finalMilestoneId = payload.milestoneId ?? existing.milestoneId;
      if (finalMilestoneId == null) {
        // 任务属于项目但没有里程碑，确保任务有里程碑
        try {
          await _projectService.ensureTasksHaveMilestone(finalProjectId);
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint(
              '[TaskCrudService.updateDetails] {event: ensureTasksHaveMilestone:failed, taskId: $taskId, projectId: $finalProjectId, error: $e, stackTrace: $stackTrace}',
            );
          }
          // 继续执行，不中断整个更新流程
        }
      }
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 更新任务标签
  Future<void> updateTags({
    required String taskId,
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
              kind != TagKind.importance;
        })
        .toList(growable: true);
    if (contextTag != null && contextTag.isNotEmpty) {
      normalized.add(TagService.normalizeSlug(contextTag));
    }
    if (priorityTag != null && priorityTag.isNotEmpty) {
      normalized.add(TagService.normalizeSlug(priorityTag));
    }
    await _tasks.updateTask(taskId, TaskUpdate(tags: normalized));

    // 层级功能已移除，不再需要同步子任务标签

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }
}

