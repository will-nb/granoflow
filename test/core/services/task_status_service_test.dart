import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/config/app_constants.dart';
import 'package:granoflow/core/services/metric_orchestrator.dart';
import 'package:granoflow/core/services/task_status_service.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/metric_snapshot.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/data/repositories/metric_repository.dart';
import 'package:granoflow/data/repositories/task_repository.dart';

import '../../presentation/test_support/fakes.dart';

void main() {
  group('TaskStatusService', () {
    late StubTaskRepository taskRepository;
    late StubFocusSessionRepository focusSessionRepository;
    late TaskStatusService service;
    final fixedNow = DateTime(2024, 2, 10, 9, 0, 0);

    setUp(() {
      taskRepository = StubTaskRepository();
      focusSessionRepository = StubFocusSessionRepository();
      service = TaskStatusService(
        taskRepository: taskRepository,
        metricOrchestrator: _StubMetricOrchestrator(),
        focusSessionRepository: focusSessionRepository,
        clock: () => fixedNow,
      );
    });

    group('markCompleted', () {
      test('should create default FocusSession when task has no running time', () async {
        // 创建一个没有运行时间记录的任务
        final task = await taskRepository.createTask(
          TaskDraft(
            title: 'Test Task',
            status: TaskStatus.pending,
          ),
        );

        // 验证任务没有运行时间记录
        final totalMinutesBefore = await focusSessionRepository.totalMinutesForTask(task.id);
        expect(totalMinutesBefore, 0);

        // 完成任务
        await service.markCompleted(taskId: task.id);

        // 验证任务状态已更新为完成
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.status, TaskStatus.completedActive);
        expect(updatedTask.endedAt, fixedNow);

        // 验证已创建默认的 FocusSession 记录默认时间
        final totalMinutesAfter = await focusSessionRepository.totalMinutesForTask(task.id);
        expect(totalMinutesAfter, AppConstants.defaultTaskCompletionMinutes);

        // 验证创建的 FocusSession 详情
        final sessions = await focusSessionRepository.listRecentSessions(taskId: task.id);
        expect(sessions.length, 1);
        expect(sessions.first.taskId, task.id);
        expect(sessions.first.actualMinutes, AppConstants.defaultTaskCompletionMinutes);
        expect(sessions.first.estimateMinutes, AppConstants.defaultTaskCompletionMinutes);
        expect(sessions.first.alarmEnabled, false);
        expect(sessions.first.endedAt, isNotNull);
      });

      test('should not create FocusSession when task already has running time', () async {
        // 创建一个任务
        final task = await taskRepository.createTask(
          TaskDraft(
            title: 'Test Task',
            status: TaskStatus.pending,
          ),
        );

        // 先创建一个已有的 FocusSession 记录时间
        final existingSession = await focusSessionRepository.startSession(
          taskId: task.id,
          estimateMinutes: 25,
          alarmEnabled: false,
        );
        await focusSessionRepository.endSession(
          sessionId: existingSession.id,
          actualMinutes: 15,
        );

        // 验证任务已有运行时间记录
        final totalMinutesBefore = await focusSessionRepository.totalMinutesForTask(task.id);
        expect(totalMinutesBefore, 15);

        // 完成任务
        await service.markCompleted(taskId: task.id);

        // 验证任务状态已更新为完成
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.status, TaskStatus.completedActive);

        // 验证运行时间没有增加（仍然是15分钟）
        final totalMinutesAfter = await focusSessionRepository.totalMinutesForTask(task.id);
        expect(totalMinutesAfter, 15);

        // 验证只有一个 FocusSession（没有创建新的）
        final sessions = await focusSessionRepository.listRecentSessions(taskId: task.id);
        expect(sessions.length, 1);
        expect(sessions.first.actualMinutes, 15);
      });

      test('should work without FocusSessionRepository (backward compatibility)', () async {
        // 创建一个没有 FocusSessionRepository 的服务（向后兼容）
        final serviceWithoutRepo = TaskStatusService(
          taskRepository: taskRepository,
          metricOrchestrator: _StubMetricOrchestrator(),
          focusSessionRepository: null,
          clock: () => fixedNow,
        );

        // 创建一个任务
        final task = await taskRepository.createTask(
          TaskDraft(
            title: 'Test Task',
            status: TaskStatus.pending,
          ),
        );

        // 完成任务（应该不会出错，即使没有 FocusSessionRepository）
        await serviceWithoutRepo.markCompleted(taskId: task.id);

        // 验证任务状态已更新为完成
        final updatedTask = await taskRepository.findById(task.id);
        expect(updatedTask, isNotNull);
        expect(updatedTask!.status, TaskStatus.completedActive);
        expect(updatedTask.endedAt, fixedNow);
      });

      test('should auto-complete parent when all siblings are completed', () async {
        // 创建父任务
        final parent = await taskRepository.createTask(
          TaskDraft(
            title: 'Parent Task',
            status: TaskStatus.pending,
          ),
        );

        // 创建两个子任务
        final child1 = await taskRepository.createTask(
          TaskDraft(
            title: 'Child 1',
            status: TaskStatus.pending,
            parentId: parent.id,
          ),
        );
        final child2 = await taskRepository.createTask(
          TaskDraft(
            title: 'Child 2',
            status: TaskStatus.pending,
            parentId: parent.id,
          ),
        );

        // 完成第一个子任务
        await service.markCompleted(taskId: child1.id);
        final parentAfterChild1 = await taskRepository.findById(parent.id);
        expect(parentAfterChild1!.status, TaskStatus.pending); // 父任务还未完成

        // 完成第二个子任务
        await service.markCompleted(taskId: child2.id);
        final parentAfterChild2 = await taskRepository.findById(parent.id);
        expect(parentAfterChild2!.status, TaskStatus.completedActive); // 父任务自动完成
        expect(parentAfterChild2.endedAt, fixedNow);
      });
    });
  });
}

class _StubMetricOrchestrator extends MetricOrchestrator {
  _StubMetricOrchestrator()
      : super(
          metricRepository: _FakeMetricRepository(),
          taskRepository: _FakeTaskRepository(),
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
      totalFocusMinutes: 0,
      pendingTasks: 0,
      pendingTodayTasks: 0,
      calculatedAt: DateTime.now(),
    );
  }

  @override
  Stream<MetricSnapshot?> watchLatest() => const Stream.empty();
}

class _FakeTaskRepository implements TaskRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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
  Future<FocusSession?> findById(int sessionId) async =>
      throw UnimplementedError();

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
  Future<int> totalMinutesForTask(int taskId) async => 0;

  @override
  Future<Map<int, int>> totalMinutesForTasks(List<int> taskIds) async {
    return {for (final taskId in taskIds) taskId: 0};
  }

  @override
  Future<int> totalMinutesOverall() async => 0;

  @override
  Stream<FocusSession?> watchActiveSession(int taskId) => const Stream.empty();
}

