import '../../data/models/milestone.dart';
import '../../data/models/project.dart';
import '../../data/models/task.dart';
import '../../data/repositories/milestone_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../constants/task_constants.dart';
import 'metric_orchestrator.dart';
import 'project_models.dart';
import 'project_service_actions.dart';
import 'project_service_helpers.dart';
import 'project_service_tasks.dart';

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
       _helpers = ProjectServiceHelpers(clock: clock),
       _tasksHelper = ProjectServiceTasks(taskRepository: taskRepository),
       _actions = ProjectServiceActions(
         projectRepository: projectRepository,
         taskRepository: taskRepository,
         metricOrchestrator: metricOrchestrator,
         helpers: ProjectServiceHelpers(clock: clock),
         tasks: ProjectServiceTasks(taskRepository: taskRepository),
         clock: clock,
       ) {
    _clock = _helpers.clock;
  }

  final ProjectRepository _projects;
  final MilestoneRepository _milestones;
  final TaskRepository _tasks;
  final MetricOrchestrator _metricOrchestrator;
  final ProjectServiceHelpers _helpers;
  final ProjectServiceTasks _tasksHelper;
  final ProjectServiceActions _actions;
  late final DateTime Function() _clock;

  Stream<List<Project>> watchActiveProjects() =>
      _projects.watchActiveProjects();

  Future<Project?> findByIsarId(int isarId) => _projects.findByIsarId(isarId);

  Future<Project?> findByProjectId(String projectId) =>
      _projects.findByProjectId(projectId);

  Future<void> updateProject(int isarId, ProjectUpdate update) =>
      _actions.updateProject(isarId, update);

  Future<Milestone?> findMilestoneById(String milestoneId) =>
      _milestones.findByMilestoneId(milestoneId);

  Stream<List<Milestone>> watchMilestones(String projectId) =>
      _milestones.watchByProjectId(projectId);

  Future<List<Milestone>> listMilestones(String projectId) =>
      _milestones.listByProjectId(projectId);

  Future<Project> createProject(ProjectBlueprint blueprint) async {
    final now = _clock();
    final projectId = _helpers.generateProjectId(now);
    final dueAt = _helpers.normalizeDueDate(blueprint.dueDate);
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
        tags: _helpers.uniqueTags(blueprint.tags),
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
          ? _helpers.normalizeDueDate(milestoneBlueprint.dueDate!)
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
          milestoneId: _helpers.generateMilestoneId(now, i),
          projectId: project.projectId,
          title: milestoneBlueprint.title,
          status: TaskStatus.pending,
          dueAt: milestoneDue,
          startedAt: null,
          endedAt: null,
          sortIndex: TaskConstants.DEFAULT_SORT_INDEX,
          tags: _helpers.uniqueTags(milestoneBlueprint.tags),
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

    await _tasksHelper.assignProjectToDescendants(taskId, project.projectId);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return project;
  }

  Future<void> snoozeProject(int isarId) => _actions.snoozeProject(isarId);

  Future<void> archiveProject(int isarId, {bool archiveActiveTasks = false}) =>
      _actions.archiveProject(isarId, archiveActiveTasks: archiveActiveTasks);

  Future<void> deleteProject(int isarId) => _actions.deleteProject(isarId);

  Future<void> completeProject(int isarId, {bool archiveActiveTasks = false}) =>
      _actions.completeProject(isarId, archiveActiveTasks: archiveActiveTasks);

  Future<void> trashProject(int isarId) => _actions.trashProject(isarId);

  Future<void> restoreProject(int isarId) => _actions.restoreProject(isarId);

  Future<void> reactivateProject(int isarId) =>
      _actions.reactivateProject(isarId);

  Future<List<Task>> listTasksForProject(String projectId) =>
      _tasksHelper.listTasksForProject(projectId);

  Future<bool> hasActiveTasks(String projectId) =>
      _tasksHelper.hasActiveTasks(projectId);
}
