import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import 'metric_orchestrator.dart';
import 'project_service_helpers.dart';
import 'project_service_tasks.dart';

/// ProjectService 状态操作方法
/// 
/// 包含项目状态变更相关的方法，如归档、完成、删除、恢复等
class ProjectServiceActions {
  ProjectServiceActions({
    required ProjectRepository projectRepository,
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    required ProjectServiceHelpers helpers,
    required ProjectServiceTasks tasks,
    DateTime Function()? clock,
  }) : _projects = projectRepository,
       _metricOrchestrator = metricOrchestrator,
       _helpers = helpers,
       _tasksHelper = tasks,
       _clock = clock ?? DateTime.now;

  final ProjectRepository _projects;
  final MetricOrchestrator _metricOrchestrator;
  final ProjectServiceHelpers _helpers;
  final ProjectServiceTasks _tasksHelper;
  final DateTime Function() _clock;

  Future<void> updateProject(int isarId, ProjectUpdate update) async {
    await _projects.update(isarId, update);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> snoozeProject(int isarId) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    final now = _clock();
    final baseDue = project.dueAt ?? _helpers.normalizeDueDate(now);
    final newDue = _helpers.addOneYear(baseDue);
    final logs = project.logs.toList(growable: true)
      ..add(
        ProjectLogEntry(
          timestamp: now,
          action: 'deadline_snoozed',
          previous: baseDue.toIso8601String(),
          next: newDue.toIso8601String(),
        ),
      );

    await _projects.update(isarId, ProjectUpdate(dueAt: newDue, logs: logs));

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> archiveProject(int isarId, {bool archiveActiveTasks = false}) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    // 如果选择归档活跃任务，则归档所有活跃任务及其子任务
    if (archiveActiveTasks) {
      await _tasksHelper.archiveActiveTasksForProject(project.projectId);
    }

    final logs = project.logs.toList(growable: true)
      ..add(ProjectLogEntry(timestamp: _clock(), action: 'archived'));

    await _projects.update(
      isarId,
      ProjectUpdate(status: TaskStatus.archived, logs: logs),
    );

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> deleteProject(int isarId) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    // 删除项目下所有任务（包括子任务）
    await _tasksHelper.deleteAllTasksForProject(project.projectId);

    await _projects.delete(isarId);
  }

  Future<void> completeProject(int isarId, {bool archiveActiveTasks = false}) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    // 如果选择归档活跃任务，则归档所有活跃任务及其子任务
    if (archiveActiveTasks) {
      await _tasksHelper.archiveActiveTasksForProject(project.projectId);
    }

    final logs = project.logs.toList(growable: true)
      ..add(ProjectLogEntry(
        timestamp: _clock(),
        action: 'completed',
        previous: project.status.name,
        next: TaskStatus.completedActive.name,
      ));

    await _projects.update(
      isarId,
      ProjectUpdate(status: TaskStatus.completedActive, logs: logs),
    );

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> trashProject(int isarId) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    // 将项目下所有任务移入回收站（包括子任务）
    await _tasksHelper.trashAllTasksForProject(project.projectId);

    final logs = project.logs.toList(growable: true)
      ..add(ProjectLogEntry(
        timestamp: _clock(),
        action: 'trashed',
        previous: project.status.name,
        next: TaskStatus.trashed.name,
      ));

    await _projects.update(
      isarId,
      ProjectUpdate(status: TaskStatus.trashed, logs: logs),
    );

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> restoreProject(int isarId) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    if (project.status != TaskStatus.trashed) {
      throw StateError(
        'Project is not in trash: current status is ${project.status.name}',
      );
    }

    final logs = project.logs.toList(growable: true)
      ..add(ProjectLogEntry(
        timestamp: _clock(),
        action: 'restored',
        previous: project.status.name,
        next: TaskStatus.pending.name,
      ));

    await _projects.update(
      isarId,
      ProjectUpdate(status: TaskStatus.pending, logs: logs),
    );

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  /// 重新激活项目（将已完成或归档的项目恢复到 pending 状态）
  Future<void> reactivateProject(int isarId) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    if (project.status != TaskStatus.completedActive &&
        project.status != TaskStatus.archived) {
      throw StateError(
        'Project cannot be reactivated: current status is ${project.status.name}',
      );
    }

    final logs = project.logs.toList(growable: true)
      ..add(ProjectLogEntry(
        timestamp: _clock(),
        action: 'reactivated',
        previous: project.status.name,
        next: TaskStatus.pending.name,
      ));

    await _projects.update(
      isarId,
      ProjectUpdate(status: TaskStatus.pending, logs: logs),
    );

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }
}

