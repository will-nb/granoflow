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

      final stored = await projectRepository.findByIsarId(project.id);
      expect(stored, isNotNull);
      expect(stored!.dueAt, DateTime(2024, 3, 1, 23, 59, 59, 999));

      final milestones = await milestoneRepository.listByProjectId(
        project.projectId,
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

      final updated = await projectRepository.findByIsarId(project.id);
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
        expect(archivedRoot?.projectId, project.projectId);

        final reassignedChild = await taskRepository.findById(child.id);
        expect(reassignedChild?.projectId, project.projectId);
        expect(reassignedChild?.parentId, root.id);
      },
    );
  });
}

class _InMemoryProjectRepository implements ProjectRepository {
  _InMemoryProjectRepository()
    : _controller = StreamController<List<Project>>.broadcast();

  final Map<int, Project> _projects = <int, Project>{};
  final StreamController<List<Project>> _controller;
  int _nextId = 1;

  @override
  Future<Project> create(ProjectDraft draft) async {
    final project = Project(
      id: _nextId++,
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
      logs: List<ProjectLogEntry>.from(draft.logs),
    );
    _projects[project.id] = project;
    _emit();
    return project;
  }

  @override
  Future<void> update(int isarId, ProjectUpdate update) async {
    final current = _projects[isarId];
    if (current == null) return;
    _projects[isarId] = current.copyWith(
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
  Future<void> delete(int isarId) async {
    _projects.remove(isarId);
    _emit();
  }

  @override
  Future<Project?> findByIsarId(int id) async => _projects[id];

  @override
  Future<Project?> findByProjectId(String projectId) async {
    for (final project in _projects.values) {
      if (project.projectId == projectId) {
        return project;
      }
    }
    return null;
  }

  @override
  Future<List<Project>> listAll() async =>
      _projects.values.toList(growable: false);

  @override
  Stream<List<Project>> watchActiveProjects() => _controller.stream;

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

  final Map<int, Milestone> _milestones = <int, Milestone>{};
  final StreamController<List<Milestone>> _controller;
  int _nextId = 1;

  @override
  Future<Milestone> create(MilestoneDraft draft) async {
    final milestone = Milestone(
      id: _nextId++,
      milestoneId: draft.milestoneId,
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
  Future<void> update(int isarId, MilestoneUpdate update) async {
    final current = _milestones[isarId];
    if (current == null) return;
    _milestones[isarId] = current.copyWith(
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
  Future<void> delete(int isarId) async {
    final removed = _milestones.remove(isarId);
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
  Future<Milestone?> findByIsarId(int id) async => _milestones[id];

  @override
  Future<Milestone?> findByMilestoneId(String milestoneId) async {
    for (final milestone in _milestones.values) {
      if (milestone.milestoneId == milestoneId) {
        return milestone;
      }
    }
    return null;
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
      id: 1,
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
    required int sessionId,
    required int actualMinutes,
    int? transferToTaskId,
    String? reflectionNote,
  }) async {}

  @override
  Future<FocusSession?> findById(int sessionId) async => null;

  @override
  Future<List<FocusSession>> listRecentSessions({
    required int taskId,
    int limit = 10,
  }) async => const <FocusSession>[];

  @override
  Future<FocusSession> startSession({
    required int taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async => FocusSession(id: 1, taskId: taskId, startedAt: DateTime.now());

  @override
  Future<int> totalMinutesForTask(int taskId) async => 0;

  @override
  Future<int> totalMinutesOverall() async => 0;

  @override
  Stream<FocusSession?> watchActiveSession(int taskId) async* {
    yield null;
  }
}
