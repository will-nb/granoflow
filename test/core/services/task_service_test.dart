import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/core/services/metric_orchestrator.dart';
import 'package:granoflow/data/models/metric_snapshot.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/data/repositories/metric_repository.dart';
import 'package:granoflow/data/repositories/task_repository.dart';

import '../../presentation/test_support/fakes.dart';

void main() {
  group('TaskService project workflows', () {
    late StubTaskRepository taskRepository;
    late StubTagRepository tagRepository;
    late TaskService service;
    final fixedNow = DateTime(2024, 2, 10, 9);

    setUp(() {
      taskRepository = StubTaskRepository();
      tagRepository = StubTagRepository();
      service = TaskService(
        taskRepository: taskRepository,
        tagRepository: tagRepository,
        metricOrchestrator: _StubMetricOrchestrator(taskRepository),
        clock: () => fixedNow,
      );
    });

    test('createProject persists descriptions on project and milestones', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Quarterly Planning',
          dueDate: DateTime(2024, 2, 29),
          description: 'Full planning narrative with 60k allowance.',
          tags: const <String>['#urgent'],
          milestones: <ProjectMilestoneBlueprint>[
            ProjectMilestoneBlueprint(
              title: 'Kickoff',
              dueDate: DateTime(2024, 3, 5),
              tags: const <String>['#timed'],
              description: 'Align stakeholders and finalize scope.',
            ),
          ],
        ),
      );

      final storedProject = await taskRepository.findById(project.id);
      final milestones = await taskRepository.listChildren(project.id);

      expect(storedProject, isNotNull);
      expect(storedProject!.description,
          equals('Full planning narrative with 60k allowance.'));

      expect(milestones, hasLength(1));
      expect(milestones.first.description,
          equals('Align stakeholders and finalize scope.'));
    });

    test('snoozeProject extends deadline by one year and logs change', () async {
      final project = await service.createProject(
        ProjectBlueprint(
          title: 'Leap Project',
          dueDate: DateTime(2024, 2, 29),
          milestones: const <ProjectMilestoneBlueprint>[],
        ),
      );

      final before = await taskRepository.findById(project.id);
      expect(before?.dueAt, isNotNull);
      final originalDueIso = before!.dueAt!.toIso8601String();

      await service.snoozeProject(project.id);

      final after = await taskRepository.findById(project.id);
      expect(after, isNotNull);

      expect(
        after!.dueAt,
        equals(DateTime(2025, 2, 28, 23, 59, 59, 999)),
        reason: 'Leap day should clamp to Feb 28 on non-leap year',
      );

      expect(after.logs.last.action, 'deadline_snoozed');
      expect(after.logs.last.previous, originalDueIso);
      expect(after.logs.last.next, after.dueAt!.toIso8601String());
    });

    test('updateDetails appends provided logs instead of replacing', () async {
      final initialLog = TaskLogEntry(
        timestamp: fixedNow,
        action: 'deadline_set',
        next: fixedNow.toIso8601String(),
      );
      final task = await taskRepository.createTask(
        TaskDraft(
          title: 'Documentation',
          status: TaskStatus.pending,
          dueAt: fixedNow,
          taskKind: TaskKind.project,
          logs: <TaskLogEntry>[initialLog],
        ),
      );

      final customLog = TaskLogEntry(
        timestamp: fixedNow.add(const Duration(minutes: 5)),
        action: 'notes_added',
        next: 'Initial outline ready',
      );

      await service.updateDetails(
        taskId: task.id,
        payload: TaskUpdate(
          description: 'Updated scope',
          logs: <TaskLogEntry>[customLog],
        ),
      );

      final updated = await taskRepository.findById(task.id);
      expect(updated, isNotNull);
      expect(updated!.description, 'Updated scope');
      expect(updated.logs.length, 2);
      expect(updated.logs.last.action, 'notes_added');
      expect(updated.logs.first.action, 'deadline_set');
    });
  });
}

class _StubMetricOrchestrator extends MetricOrchestrator {
  _StubMetricOrchestrator(TaskRepository taskRepository)
    : super(
        metricRepository: _FakeMetricRepository(),
        taskRepository: taskRepository,
        focusRepository: _FakeFocusSessionRepository(),
      );

  @override
  Future<MetricSnapshot> requestRecompute(MetricRecomputeReason reason) async {
    return MetricSnapshot(
      id: 0,
      totalCompletedTasks: 0,
      totalFocusMinutes: 0,
      pendingTasks: 0,
      pendingTodayTasks: 0,
      calculatedAt: DateTime.now(),
    );
  }
}

class _FakeMetricRepository implements MetricRepository {
  @override
  Future<void> invalidate() async {}

  @override
  Future<MetricSnapshot> recompute({
    required Iterable<Task> tasks,
    required int totalFocusMinutes,
  }) async {
    return MetricSnapshot(
      id: 0,
      totalCompletedTasks: 0,
      totalFocusMinutes: totalFocusMinutes,
      pendingTasks: tasks.length,
      pendingTodayTasks: 0,
      calculatedAt: DateTime.now(),
    );
  }

  @override
  Stream<MetricSnapshot?> watchLatest() => const Stream.empty();
}

class _FakeFocusSessionRepository implements FocusSessionRepository {
  @override
  Future<void> endSession({
    required int sessionId,
    required int actualMinutes,
    int? transferToTaskId,
    String? reflectionNote,
  }) async => throw UnimplementedError();

  @override
  Future<FocusSession?> findById(int sessionId) async => throw UnimplementedError();

  @override
  Future<List<FocusSession>> listRecentSessions({
    required int taskId,
    int limit = 10,
  }) async => throw UnimplementedError();

  @override
  Future<FocusSession> startSession({
    required int taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async => throw UnimplementedError();

  @override
  Future<int> totalMinutesForTask(int taskId) async => throw UnimplementedError();

  @override
  Future<int> totalMinutesOverall() async => 0;

  @override
  Stream<FocusSession?> watchActiveSession(int taskId) => const Stream.empty();
}
