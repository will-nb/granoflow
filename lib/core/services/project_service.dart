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

  Future<void> archiveProject(int isarId) async {
    final project = await _projects.findByIsarId(isarId);
    if (project == null) {
      throw StateError('Project not found: $isarId');
    }

    final logs = project.logs.toList(growable: true)
      ..add(ProjectLogEntry(timestamp: _clock(), action: 'archived'));

    await _projects.update(
      isarId,
      ProjectUpdate(status: TaskStatus.archived, logs: logs),
    );

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
  }

  Future<void> deleteProject(int isarId) {
    return _projects.delete(isarId);
  }

  Future<List<Task>> listTasksForProject(String projectId) async {
    final allTasks = await _tasks.listAll();
    return allTasks
        .where((task) => task.projectId == projectId)
        .toList(growable: false);
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
