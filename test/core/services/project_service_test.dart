import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/project_models.dart';
import 'package:granoflow/core/services/project_service.dart';
import 'package:granoflow/core/services/metric_orchestrator.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/data/models/metric_snapshot.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/milestone_repository.dart';
import 'package:granoflow/data/repositories/project_repository.dart';
import 'package:granoflow/data/repositories/metric_repository.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/core/providers/project_filter_providers.dart';

import '../../presentation/test_support/fakes.dart';

void main() {
  group('ProjectService', () {
    late _InMemoryProjectRepository projectRepository;
    late _InMemoryMilestoneRepository milestoneRepository;
    late StubTaskRepository taskRepository;
    late MetricOrchestrator metricOrchestrator;
    late ProjectService service;

    setUp(() {
      projectRepository = _InMemoryProjectRepository();
      milestoneRepository = _InMemoryMilestoneRepository();
      taskRepository = StubTaskRepository();
      metricOrchestrator = MetricOrchestrator(
        metricRepository: _NoopMetricRepository(),
        taskRepository: taskRepository,
        focusRepository: _NoopFocusSessionRepository(),
      );
      service = ProjectService(
        projectRepository: projectRepository,
        milestoneRepository: milestoneRepository,
        taskRepository: taskRepository,
        metricOrchestrator: metricOrchestrator,
        clock: () => DateTime(2024, 2, 10, 9),
      );
    });

    test('createProject stores project and milestones with metadata', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Quarterly Planning',
          dueDate: DateTime(2024, 3, 1),
          description: 'Full planning narrative with 60k allowance.',
          tags: const <String>['#urgent'],
          milestones: <ProjectMilestoneBlueprint>[
            ProjectMilestoneBlueprint(
              title: 'Kickoff',
              dueDate: DateTime(2024, 3, 5),
              tags: <String>['#timed'],
              description: 'Align stakeholders and finalize scope.',
            ),
          ],
        ),
      );

      expect(project.title, 'Quarterly Planning');
      expect(
        project.description,
        'Full planning narrative with 60k allowance.',
      );
      expect(project.tags, contains('#urgent'));
      expect(project.logs.last.action, 'deadline_set');

      final stored = await projectRepository.findById(project.id);
      expect(stored, isNotNull);
      expect(stored!.dueAt, DateTime(2024, 3, 1, 23, 59, 59, 999));

      final milestones = await milestoneRepository.listByProjectId(
        project.id,
      );
      expect(milestones, hasLength(1));
      expect(milestones.first.title, 'Kickoff');
      expect(milestones.first.logs.last.action, 'deadline_set');
    });

    test('snoozeProject extends deadline and appends snooze log', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Leap Initiative',
          dueDate: DateTime(2024, 2, 29),
          milestones: <ProjectMilestoneBlueprint>[],
        ),
      );

      await service.snoozeProject(project.id);

      final updated = await projectRepository.findById(project.id);
      expect(updated, isNotNull);
      expect(updated!.dueAt, DateTime(2025, 2, 28, 23, 59, 59, 999));
      expect(updated.logs.last.action, 'deadline_snoozed');
    });

    test(
      'convertTaskToProject creates project and assigns descendants',
      () async {
        final root = await taskRepository.createTask(
          TaskDraft(
            title: 'Convert Me',
            status: TaskStatus.pending,
            dueAt: DateTime(2024, 3, 10),
            description: 'Legacy project container',
          ),
        );

        final child = await taskRepository.createTask(
          TaskDraft(
            title: 'Refine Requirements',
            status: TaskStatus.pending,
            parentId: root.id,
            sortIndex: 1,
          ),
        );

        final project = await service.convertTaskToProject(root.id);

        expect(project.title, 'Convert Me');

        final archivedRoot = await taskRepository.findById(root.id);
        expect(archivedRoot?.status, TaskStatus.archived);
        expect(archivedRoot?.projectId, project.id);

        final reassignedChild = await taskRepository.findById(child.id);
        expect(reassignedChild?.projectId, project.id);
        expect(reassignedChild?.parentId, root.id);
      },
    );

    test('completeProject updates status to completedActive', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Test Project',
          dueDate: DateTime(2024, 3, 1),
          milestones: <ProjectMilestoneBlueprint>[],
        ),
      );

      await service.completeProject(project.id);

      final updated = await projectRepository.findById(project.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.completedActive);
      expect(updated.logs.last.action, 'completed');
      expect(updated.logs.last.previous, TaskStatus.pending.name);
      expect(updated.logs.last.next, TaskStatus.completedActive.name);
    });

    test('trashProject updates status to trashed', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Test Project',
          dueDate: DateTime(2024, 3, 1),
          milestones: <ProjectMilestoneBlueprint>[],
        ),
      );

      await service.trashProject(project.id);

      final updated = await projectRepository.findById(project.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.trashed);
      expect(updated.logs.last.action, 'trashed');
    });

    test('restoreProject updates status from trashed to pending', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Test Project',
          dueDate: DateTime(2024, 3, 1),
          milestones: <ProjectMilestoneBlueprint>[],
        ),
      );

      // 先移到回收站
      await service.trashProject(project.id);

      // 然后恢复
      await service.restoreProject(project.id);

      final updated = await projectRepository.findById(project.id);
      expect(updated, isNotNull);
      expect(updated!.status, TaskStatus.pending);
      expect(updated.logs.last.action, 'restored');
      expect(updated.logs.last.previous, TaskStatus.trashed.name);
      expect(updated.logs.last.next, TaskStatus.pending.name);
    });

    test('restoreProject throws when project is not trashed', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Test Project',
          dueDate: DateTime(2024, 3, 1),
          milestones: <ProjectMilestoneBlueprint>[],
        ),
      );

      expect(
        () => service.restoreProject(project.id),
        throwsA(isA<StateError>()),
      );
    });

    test('updateProject updates project fields', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Original Title',
          dueDate: DateTime(2024, 3, 1),
          description: 'Original description',
          milestones: <ProjectMilestoneBlueprint>[],
        ),
      );

      final newDeadline = DateTime(2024, 4, 1);
      await service.updateProject(
        project.id,
        ProjectUpdate(
          title: 'Updated Title',
          dueAt: newDeadline,
          description: 'Updated description',
        ),
      );

      final updated = await projectRepository.findById(project.id);
      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Title');
      expect(updated.description, 'Updated description');
      expect(updated.dueAt, newDeadline);
    });
  });
}

class _InMemoryProjectRepository implements ProjectRepository {
  _InMemoryProjectRepository()
    : _controller = StreamController<List<Project>>.broadcast();

  final Map<int, Project> _projects = <int, Project>{};
  final StreamController<List<Project>> _controller;

  @override
  Future<Project?> findById(String id) async {
    try {
      return _projects.values.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
  int _nextId = 1;

  @override
  Future<Project> create(ProjectDraft draft) async {
    final project = Project(
      id: (_nextId++).toString(),

      title: draft.title,
      status: draft.status,
      dueAt: draft.dueAt,
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortIndex: draft.sortIndex,
      tags: List<String>.from(draft.tags),
      templateLockCount: draft.templateLockCount,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
      description: draft.description,
      logs: List<ProjectLogEntry>.from(draft.logs),
    );
    _projects[project.id] = project;
    _emit();
    return project;
  }

  @override
  Future<void> update(String id, ProjectUpdate update) async {
    final current = _projects[id];
    if (current == null) return;
    _projects[id] = current.copyWith(
      title: update.title,
      status: update.status,
      dueAt: update.dueAt,
      startedAt: update.startedAt,
      endedAt: update.endedAt,
      sortIndex: update.sortIndex,
      tags: update.tags,
      templateLockCount: current.templateLockCount + update.templateLockDelta,
      allowInstantComplete: update.allowInstantComplete,
      description: update.description,
      logs: update.logs,
      updatedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _projects.remove(id);
    _emit();
  }

  @override
  Future<Project?> findByProjectId(String projectId) async {
    for (final project in _projects.values) {
      if (project.id == projectId) {
        return project;
      }
    }
    return null;
  }

  @override
  Future<List<Project>> listAll() async =>
      _projects.values.toList(growable: false);

  @override
  Future<Project> createProjectWithId(
    ProjectDraft draft,
    String projectId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    final project = Project(
      id: projectId,

      title: draft.title,
      status: draft.status,
      dueAt: draft.dueAt,
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sortIndex: draft.sortIndex,
      tags: List<String>.from(draft.tags),
      templateLockCount: draft.templateLockCount,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
      description: draft.description,
      logs: List<ProjectLogEntry>.from(draft.logs),
    );
    _projects[project.id] = project;
    _emit();
    return project;
  }

  @override
  Stream<List<Project>> watchActiveProjects() =>
      watchProjectsByStatus(ProjectFilterStatus.active);

  @override
  Stream<List<Project>> watchProjectsByStatus(ProjectFilterStatus status) {
    return _controller.stream.map((allProjects) {
      return allProjects
          .where((project) {
            switch (status) {
              case ProjectFilterStatus.all:
                return project.status != TaskStatus.pseudoDeleted;
              case ProjectFilterStatus.active:
                return project.status == TaskStatus.pending ||
                    project.status == TaskStatus.doing;
              case ProjectFilterStatus.completed:
                return project.status == TaskStatus.completedActive;
              case ProjectFilterStatus.archived:
                return project.status == TaskStatus.archived;
              case ProjectFilterStatus.trash:
                return project.status == TaskStatus.trashed;
            }
          })
          .toList(growable: false);
    });
  }

  @override
  Stream<List<Project>> watchProjectsByStatuses(
    Set<TaskStatus> allowedStatuses,
  ) {
    return _controller.stream.map((allProjects) {
      return allProjects
          .where((project) {
            // 排除伪删除状态
            if (project.status == TaskStatus.pseudoDeleted) {
              return false;
            }
            // 只返回状态在允许集合中的项目
            return allowedStatuses.contains(project.status);
          })
          .toList(growable: false);
    });
  }

  void _emit() {
    final snapshot = _projects.values.toList(growable: false);
    if (_controller.hasListener) {
      _controller.add(snapshot);
    }
  }
}

class _InMemoryMilestoneRepository implements MilestoneRepository {
  _InMemoryMilestoneRepository()
    : _controller = StreamController<List<Milestone>>.broadcast();

  final Map<String, Milestone> _milestones = <String, Milestone>{};
  final StreamController<List<Milestone>> _controller;

  @override
  Future<Milestone?> findById(String id) async {
    try {
      return _milestones.values.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
  int _nextId = 1;

  @override
  Future<Milestone> create(MilestoneDraft draft) async {
    final milestone = Milestone(
      id: (_nextId++).toString(),

      projectId: draft.projectId,
      title: draft.title,
      status: draft.status,
      dueAt: draft.dueAt,
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sortIndex: draft.sortIndex,
      tags: List<String>.from(draft.tags),
      templateLockCount: draft.templateLockCount,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
      description: draft.description,
      logs: List<MilestoneLogEntry>.from(draft.logs),
    );
    _milestones[milestone.id] = milestone;
    _emitForProject(milestone.projectId);
    return milestone;
  }

  @override
  Future<void> update(String id, MilestoneUpdate update) async {
    final current = _milestones[id];
    if (current == null) return;
    _milestones[id] = current.copyWith(
      title: update.title,
      status: update.status,
      dueAt: update.dueAt,
      startedAt: update.startedAt,
      endedAt: update.endedAt,
      sortIndex: update.sortIndex,
      tags: update.tags,
      templateLockCount: current.templateLockCount + update.templateLockDelta,
      allowInstantComplete: update.allowInstantComplete,
      description: update.description,
      logs: update.logs,
    );
    _emitForProject(current.projectId);
  }

  @override
  Future<void> delete(String id) async {
    final removed = _milestones.remove(id);
    if (removed != null) {
      _emitForProject(removed.projectId);
    }
  }

  @override
  Stream<List<Milestone>> watchByProjectId(String projectId) {
    return _controller.stream.map(
      (list) => list.where((m) => m.projectId == projectId).toList(),
    );
  }

  @override
  Future<List<Milestone>> listByProjectId(String projectId) async {
    return _milestones.values
        .where((milestone) => milestone.projectId == projectId)
        .toList(growable: false);
  }

  @override
  Future<Milestone?> findByMilestoneId(String milestoneId) async {
    for (final milestone in _milestones.values) {
      if (milestone.id == milestoneId) {
        return milestone;
      }
    }
    return null;
  }

  @override
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async {
    final milestone = Milestone(
      id: milestoneId,

      projectId: draft.projectId,
      title: draft.title,
      status: draft.status,
      dueAt: draft.dueAt,
      startedAt: draft.startedAt,
      endedAt: draft.endedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sortIndex: draft.sortIndex,
      tags: List<String>.from(draft.tags),
      templateLockCount: draft.templateLockCount,
      seedSlug: draft.seedSlug,
      allowInstantComplete: draft.allowInstantComplete,
      description: draft.description,
      logs: List<MilestoneLogEntry>.from(draft.logs),
    );
    _milestones[milestone.id] = milestone;
    _emitForProject(milestone.projectId);
    return milestone;
  }

  @override
  Future<List<Milestone>> listAll() async {
    return _milestones.values.toList(growable: false);
  }

  @override
  Future<void> setMilestoneProjectIsarId(
    int milestoneId,
    int projectIsarId,
  ) async {
    // 测试中不需要实现，因为内存实现不维护 Isar ID 关系
  }

  void _emitForProject(String projectId) {
    final snapshot = _milestones.values.toList(growable: false);
    if (_controller.hasListener) {
      _controller.add(snapshot);
    }
  }
}

class _NoopMetricRepository implements MetricRepository {
  MetricSnapshot? _latest;

  @override
  Future<MetricSnapshot> recompute({
    required Iterable<Task> tasks,
    required int totalFocusMinutes,
  }) async {
    _latest = MetricSnapshot(
      id: '1',
      totalCompletedTasks: 0,
      totalFocusMinutes: totalFocusMinutes,
      pendingTasks: tasks.length,
      pendingTodayTasks: 0,
      calculatedAt: DateTime.now(),
    );
    return _latest!;
  }

  @override
  Future<void> invalidate() async {
    _latest = null;
  }

  @override
  Stream<MetricSnapshot?> watchLatest() async* {
    yield _latest;
  }
}

class _NoopFocusSessionRepository implements FocusSessionRepository {
  @override
  Future<void> endSession({
    required String sessionId,
    required int actualMinutes,
    String? transferToTaskId,
    String? reflectionNote,
  }) async {}

  @override
  Future<FocusSession?> findById(String sessionId) async => null;

  @override
  Future<List<FocusSession>> listRecentSessions({
    required String taskId,
    int limit = 10,
  }) async => const <FocusSession>[];

  @override
  Future<FocusSession> startSession({
    required String taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async => FocusSession(id: '1', taskId: taskId, startedAt: DateTime.now());

  @override
  Future<int> totalMinutesForTask(String taskId) async => 0;

  @override
  Future<Map<String, int>> totalMinutesForTasks(List<String> taskIds) async {
    return {for (final taskId in taskIds) taskId: 0};
  }

  @override
  Future<int> totalMinutesOverall() async => 0;

  @override
  Stream<FocusSession?> watchActiveSession(String taskId) async* {
    yield null;
  }
}
