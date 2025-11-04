import 'dart:math';

import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../constants/task_constants.dart';
import 'metric_orchestrator.dart';
import 'project_models.dart';

class ProjectService {
  ProjectService({
    required ProjectRepository projectRepository,
    required MilestoneRepository milestoneRepository,
    required TaskRepository taskRepository,
    required MetricOrchestrator metricOrchestrator,
    DateTime Function()? clock,
  }) : _projects = projectRepository,
       _milestones = milestoneRepository,
       _tasks = taskRepository,
       _metricOrchestrator = metricOrchestrator,
       _clock = clock ?? DateTime.now;

  final ProjectRepository _projects;
  final MilestoneRepository _milestones;
  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final DateTime Function() _clock;
  final Random _random = Random();

  Stream<List<Project>> watchActiveProjects() =>
      _projects.watchActiveProjects();

  Future<Project?> findByIsarId(int isarId) => _projects.findByIsarId(isarId);

  Future<Project?> findByProjectId(String projectId) =>
      _projects.findByProjectId(projectId);

  Future<void> updateProject(int isarId, ProjectUpdate update) async {
    await _projects.update(isarId, update);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<Milestone?> findMilestoneById(String milestoneId) =>
      _milestones.findByMilestoneId(milestoneId);

  Stream<List<Milestone>> watchMilestones(String projectId) =>
      _milestones.watchByProjectId(projectId);

  Future<List<Milestone>> listMilestones(String projectId) =>
      _milestones.listByProjectId(projectId);

  Future<Project> createProject(ProjectBlueprint blueprint) async {
    final now = _clock();
    final projectId = _generateProjectId(now);
    final dueAt = _normalizeDueDate(blueprint.dueDate);
    final projectLogs = <ProjectLogEntry>[
      ProjectLogEntry(
        timestamp: now,
        action: 'deadline_set',
        next: dueAt.toIso8601String(),
      ),
    ];

    final project = await _projects.create(
      ProjectDraft(
        projectId: projectId,
        title: blueprint.title,
        status: TaskStatus.pending,
        dueAt: dueAt,
        startedAt: null,
        endedAt: null,
        sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
        tags: _uniqueTags(blueprint.tags),
        templateLockCount: 0,
        seedSlug: null,
        allowInstantComplete: false,
        description: blueprint.description,
        logs: projectLogs,
      ),
    );

    for (var i = 0; i < blueprint.milestones.length; i++) {
      final milestoneBlueprint = blueprint.milestones[i];
      final milestoneDue = milestoneBlueprint.dueDate != null
          ? _normalizeDueDate(milestoneBlueprint.dueDate!)
          : null;
      final milestoneLogs = <MilestoneLogEntry>[];
      if (milestoneDue != null) {
        milestoneLogs.add(
          MilestoneLogEntry(
            timestamp: now,
            action: 'deadline_set',
            next: milestoneDue.toIso8601String(),
          ),
        );
      }
      await _milestones.create(
        MilestoneDraft(
          milestoneId: _generateMilestoneId(now, i),
          projectId: project.projectId,
          title: milestoneBlueprint.title,
          status: TaskStatus.pending,
          dueAt: milestoneDue,
          startedAt: null,
          endedAt: null,
          sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
          tags: _uniqueTags(milestoneBlueprint.tags),
          templateLockCount: 0,
          seedSlug: null,
          allowInstantComplete: false,
          description: milestoneBlueprint.description,
          logs: milestoneLogs,
        ),
      );
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return project;
  }

  Future<Project> convertTaskToProject(int taskId) async {
    final task = await _tasks.findById(taskId);
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }

    final now = _clock();
    final project = await createProject(
      ProjectBlueprint(
        title: task.title,
        dueDate: task.dueAt ?? now,
        description: task.description,
        tags: task.tags,
        milestones: const <ProjectMilestoneBlueprint>[],
      ),
    );

    final updatedLogs = task.logs.toList(growable: true)
      ..add(
        TaskLogEntry(
          timestamp: now,
          action: 'converted_to_project',
          next: project.projectId,
        ),
      );

    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        status: TaskStatus.archived,
        projectId: project.projectId,
        clearParent: true,
        clearMilestone: true,
        logs: updatedLogs,
      ),
    );

    await _assignProjectToDescendants(taskId, project.projectId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return project;
  }

  Future<void> snoozeProject(int isarId) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    final now = _clock();
    final baseDue = project.dueAt ?? _normalizeDueDate(now);
    final newDue = _addOneYear(baseDue);
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
      await _archiveActiveTasksForProject(project.projectId);
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
    await _deleteAllTasksForProject(project.projectId);

    await _projects.delete(isarId);
  }

  Future<void> completeProject(int isarId, {bool archiveActiveTasks = false}) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    // 如果选择归档活跃任务，则归档所有活跃任务及其子任务
    if (archiveActiveTasks) {
      await _archiveActiveTasksForProject(project.projectId);
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
    await _trashAllTasksForProject(project.projectId);

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

  Future<List<Task>> listTasksForProject(String projectId) async {
    final allTasks = await _tasks.listAll();
    return allTasks
        .where((task) => task.projectId == projectId)
        .toList(growable: false);
  }

  /// 检查项目下是否有活跃任务
  Future<bool> hasActiveTasks(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    return tasks.any((task) =>
        task.status == TaskStatus.pending || task.status == TaskStatus.doing);
  }

  /// 递归获取任务的所有后代任务（包括子任务的子任务）
  Future<List<Task>> _getAllDescendants(int taskId) async {
    final result = <Task>[];
    final children = await _tasks.listChildren(taskId);
    for (final child in children) {
      result.add(child);
      result.addAll(await _getAllDescendants(child.id));
    }
    return result;
  }

  /// 归档项目下所有活跃任务及其子任务
  Future<void> _archiveActiveTasksForProject(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    final activeTasks = tasks.where((task) =>
        task.status == TaskStatus.pending || task.status == TaskStatus.doing);
    
    for (final task in activeTasks) {
      // archiveTask会自动归档所有子任务
      await _tasks.archiveTask(task.id);
    }
  }

  /// 将项目下所有任务移入回收站（包括子任务）
  Future<void> _trashAllTasksForProject(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    
    for (final task in tasks) {
      // softDelete会自动将子任务移入回收站
      await _tasks.softDelete(task.id);
    }
  }

  /// 删除项目下所有任务（包括子任务）
  Future<void> _deleteAllTasksForProject(String projectId) async {
    final tasks = await listTasksForProject(projectId);
    
    // 收集所有需要删除的任务ID（包括子任务）
    final taskIdsToDelete = <int>{};
    for (final task in tasks) {
      taskIdsToDelete.add(task.id);
      final descendants = await _getAllDescendants(task.id);
      taskIdsToDelete.addAll(descendants.map((t) => t.id));
    }
    
    // 将所有任务标记为 pseudoDeleted
    for (final taskId in taskIdsToDelete) {
      await _tasks.markStatus(taskId: taskId, status: TaskStatus.pseudoDeleted);
    }
    
    // 立即清理标记为 pseudoDeleted 的任务
    await _tasks.purgeObsolete(DateTime.now());
  }

  Future<void> _assignProjectToDescendants(int taskId, String projectId) async {
    final children = await _tasks.listChildren(taskId);
    for (final child in children) {
      await _tasks.updateTask(child.id, TaskUpdate(projectId: projectId));
      await _assignProjectToDescendants(child.id, projectId);
    }
  }

  DateTime _normalizeDueDate(DateTime localDate) {
    return DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
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

  List<String> _uniqueTags(Iterable<String> tags) {
    final result = <String>[];
    for (final tag in tags) {
      if (tag.isEmpty) continue;
      if (result.contains(tag)) continue;
      result.add(tag);
    }
    return result;
  }

  String _generateProjectId(DateTime now) {
    final suffix = _random.nextInt(1 << 20).toRadixString(16).padLeft(5, '0');
    return 'prj-${now.millisecondsSinceEpoch}-$suffix';
  }

  String _generateMilestoneId(DateTime now, int index) {
    final suffix = _random.nextInt(1 << 20).toRadixString(16).padLeft(5, '0');
    return 'mil-${now.millisecondsSinceEpoch}-$index-$suffix';
  }
}
