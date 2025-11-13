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

  Future<Project?> findById(String id) => _projects.findById(id);

  Future<List<Project>> listAll() => _projects.listAll();

  Future<void> updateProject(String id, ProjectUpdate update) =>
      _actions.updateProject(id, update);

  Future<Milestone?> findMilestoneById(String milestoneId) =>
      _milestones.findById(milestoneId);

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

    final project = await _projects.createProjectWithId(
      ProjectDraft(
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
      projectId,
      now,
      now,
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
      await _milestones.createMilestoneWithId(
        MilestoneDraft(
          projectId: project.id,
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
        _helpers.generateMilestoneId(now, i),
        now,
        now,
      );
    }

    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return project;
  }

    Future<Project> convertTaskToProject(String taskId) async {
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
          next: project.id,
        ),
      );

    await _tasks.updateTask(
      taskId,
      TaskUpdate(
        status: TaskStatus.archived,
        projectId: project.id,
        clearParent: true,
        clearMilestone: true,
        logs: updatedLogs,
      ),
    );

    await _tasksHelper.assignProjectToDescendants(taskId, project.id);
    await _metricOrchestrator.requestRecompute(MetricRecomputeReason.task);
    return project;
  }

  Future<void> snoozeProject(String id) => _actions.snoozeProject(id);

  Future<void> archiveProject(String id, {bool archiveActiveTasks = false}) =>
      _actions.archiveProject(id, archiveActiveTasks: archiveActiveTasks);

  Future<void> deleteProject(String id) => _actions.deleteProject(id);

  Future<void> completeProject(String id, {bool archiveActiveTasks = false}) =>
      _actions.completeProject(id, archiveActiveTasks: archiveActiveTasks);

  Future<void> trashProject(String id) => _actions.trashProject(id);

  Future<void> restoreProject(String id) => _actions.restoreProject(id);

  Future<void> reactivateProject(String id) => _actions.reactivateProject(id);

  Future<List<Task>> listTasksForProject(String projectId) =>
      _tasksHelper.listTasksForProject(projectId);

  Future<bool> hasActiveTasks(String projectId) =>
      _tasksHelper.hasActiveTasks(projectId);

  /// 确保项目中的任务都有里程碑
  ///
  /// 如果项目中有任务没有分配到里程碑，自动将它们分配到项目的第一个里程碑
  /// 第一个里程碑的确定规则：按截止日期（第一优先）和 sortIndex（第二优先）排序
  ///
  /// [projectId] 项目ID
  /// 返回修复的任务数量
  Future<int> ensureTasksHaveMilestone(String projectId) async {
    // 获取项目的所有里程碑
    final milestones = await _milestones.listByProjectId(projectId);
    
    // 如果项目没有里程碑，直接返回（不需要修复）
    if (milestones.isEmpty) {
      return 0;
    }

    // 按截止日期（第一优先）和 sortIndex（第二优先）排序
    final sortedMilestones = List<Milestone>.from(milestones);
    sortedMilestones.sort((a, b) {
      // 首先按截止日期排序（升序）
      if (a.dueAt != null && b.dueAt != null) {
        final dateCompare = a.dueAt!.compareTo(b.dueAt!);
        if (dateCompare != 0) {
          return dateCompare;
        }
      } else if (a.dueAt != null) {
        return -1; // a 有截止日期，b 没有，a 排在前面
      } else if (b.dueAt != null) {
        return 1; // b 有截止日期，a 没有，b 排在前面
      }
      // 如果截止日期相同或都没有，按 sortIndex 排序（升序）
      return a.sortIndex.compareTo(b.sortIndex);
    });

    // 获取第一个里程碑
    final firstMilestone = sortedMilestones.first;

    // 获取项目的所有任务
    final allTasks = await _tasks.listAll();
    
    // 查找项目中 milestoneId 为 null 的任务
    final unmilestonedTasks = allTasks.where((task) {
      return task.projectId == projectId && task.milestoneId == null;
    }).toList();

    if (unmilestonedTasks.isEmpty) {
      return 0;
    }

    // 批量更新这些任务的 milestoneId
    final updates = <String, TaskUpdate>{};
    for (final task in unmilestonedTasks) {
      updates[task.id] = TaskUpdate(milestoneId: firstMilestone.id);
    }

    await _tasks.batchUpdate(updates);

    return unmilestonedTasks.length;
  }
}
