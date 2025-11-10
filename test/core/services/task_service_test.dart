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
  group('TaskService', () {
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
      id: '0',
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
      id: '0',
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
    required String sessionId,
    required int actualMinutes,
    String? transferToTaskId,
    String? reflectionNote,
  }) async => throw UnimplementedError();

  @override
  Future<FocusSession?> findById(String sessionId) async =>
      throw UnimplementedError();

  @override
  Future<List<FocusSession>> listRecentSessions({
    required String taskId,
    int limit = 10,
  }) async => throw UnimplementedError();

  @override
  Future<FocusSession> startSession({
    required String taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) async => throw UnimplementedError();

  @override
  Future<int> totalMinutesForTask(String taskId) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, int>> totalMinutesForTasks(List<String> taskIds) async {
    return {for (final taskId in taskIds) taskId: 0};
  }

  @override
  Future<int> totalMinutesOverall() async => 0;

  @override
  Stream<FocusSession?> watchActiveSession(String taskId) =>
      const Stream.empty();
}
