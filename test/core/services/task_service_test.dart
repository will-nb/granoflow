import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/core/services/metric_orchestrator.dart';
import 'package:granoflow/core/services/milestone_service.dart';
import 'package:granoflow/core/services/project_service.dart';
import 'package:granoflow/core/services/project_models.dart';
import 'package:granoflow/data/models/metric_snapshot.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/data/repositories/metric_repository.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/data/repositories/milestone_repository.dart';

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
        milestoneService: MilestoneService(
          milestoneRepository: _StubMilestoneRepository(),
          clock: () => fixedNow,
        ),
        projectService: _StubProjectService(),
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

  @override
  Future<void> updateSessionActualMinutes({
    required String sessionId,
    required int actualMinutes,
  }) async => throw UnimplementedError();

  @override
  Future<Map<DateTime, int>> getFocusMinutesByDateRange({
    required DateTime start,
    required DateTime end,
    List<String>? taskIds,
  }) async => throw UnimplementedError();

  @override
  Future<List<FocusSession>> listSessionsByDateRange({
    required DateTime start,
    required DateTime end,
    List<String>? taskIds,
  }) async => throw UnimplementedError();
}

class _StubMilestoneRepository implements MilestoneRepository {
  @override
  Future<Milestone?> findById(String id) async => null;

  @override
  Future<Milestone> create(MilestoneDraft draft) async => throw UnimplementedError();

  @override
  Future<void> update(String id, MilestoneUpdate update) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Stream<List<Milestone>> watchByProjectId(String projectId) => const Stream.empty();

  @override
  Future<List<Milestone>> listByProjectId(String projectId) async => [];

  @override
  Future<Milestone> createMilestoneWithId(
    MilestoneDraft draft,
    String milestoneId,
    DateTime createdAt,
    DateTime updatedAt,
  ) async => throw UnimplementedError();

  @override
  Future<List<Milestone>> listAll() async => [];
}

class _StubProjectService implements ProjectService {
  @override
  Stream<List<Project>> watchActiveProjects() => const Stream.empty();

  @override
  Future<Project?> findById(String id) async => null;

  @override
  Future<List<Project>> listAll() async => [];

  @override
  Future<void> updateProject(String id, ProjectUpdate update) async => throw UnimplementedError();

  @override
  Future<Milestone?> findMilestoneById(String milestoneId) async => null;

  @override
  Stream<List<Milestone>> watchMilestones(String projectId) => const Stream.empty();

  @override
  Future<List<Milestone>> listMilestones(String projectId) async => [];

  @override
  Future<Project> createProject(ProjectBlueprint blueprint) async => throw UnimplementedError();

  @override
  Future<Project> convertTaskToProject(String taskId) async => throw UnimplementedError();

  @override
  Future<void> snoozeProject(String id) async => throw UnimplementedError();

  @override
  Future<void> archiveProject(String id, {bool archiveActiveTasks = false}) async => throw UnimplementedError();

  @override
  Future<void> deleteProject(String id) async => throw UnimplementedError();

  @override
  Future<void> completeProject(String id, {bool archiveActiveTasks = false}) async => throw UnimplementedError();

  @override
  Future<void> trashProject(String id) async => throw UnimplementedError();

  @override
  Future<void> restoreProject(String id) async => throw UnimplementedError();

  @override
  Future<void> reactivateProject(String id) async => throw UnimplementedError();

  @override
  Future<List<Task>> listTasksForProject(String projectId) async => [];

  @override
  Future<bool> hasActiveTasks(String projectId) async => false;

  @override
  Future<int> ensureTasksHaveMilestone(String projectId) async => 0;
}
