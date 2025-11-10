import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/core/services/metric_orchestrator.dart';
import 'package:granoflow/core/services/task_hierarchy_service.dart';
import 'package:granoflow/data/models/focus_session.dart';
import 'package:granoflow/data/models/metric_snapshot.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/focus_session_repository.dart';
import 'package:granoflow/data/repositories/metric_repository.dart';
import 'package:granoflow/data/repositories/task_repository.dart';

void main() {
  group('TaskHierarchyService.moveToParent', () {
    late _TestTaskRepository repository;
    late TaskHierarchyService service;

    setUp(() {
      repository = _TestTaskRepository({
        '1': _task(id: '1', parentId: null),
        '2': _task(id: '2', parentId: null),
      });
      final orchestrator = MetricOrchestrator(
        metricRepository: _StubMetricRepository(),
        taskRepository: repository,
        focusRepository: _StubFocusSessionRepository(),
      );
      service = TaskHierarchyService(
        taskRepository: repository,
        metricOrchestrator: orchestrator,
      );
    });

    test('updates parentId, sortIndex and dueDate when provided', () async {
      final due = DateTime(2025, 2, 2);

      await service.moveToParent(
        taskId: '1',
        parentId: '2',
        sortIndex: 4200,
        dueDate: due,
      );

      final updated = repository.tasks['1']!;
      expect(updated.parentId, '2');
      expect(updated.sortIndex, 4200);
      expect(updated.dueAt, due);
      expect(repository.lastUpdate?.dueAt, due);
    });

    test('clearParent removes parentId when promoted to root', () async {
      repository.tasks['1'] = _task(id: '1', parentId: '2');

      await service.moveToParent(
        taskId: '1',
        parentId: null,
        sortIndex: 100,
        clearParent: true,
      );

      final updated = repository.tasks['1']!;
      expect(updated.parentId, isNull);
      expect(updated.sortIndex, 100);
      expect(repository.lastUpdate?.clearParent, isTrue);
    });
  });
}

Task _task({required String id, String? parentId}) {
  final now = DateTime(2025, 1, 1);
  return Task(
    id: id,

    title: 'Task $id',
    status: TaskStatus.pending,
    dueAt: DateTime(2025, 1, 2),
    createdAt: now,
    updatedAt: now,
    parentId: parentId,
    sortIndex: 1000,
  );
}

class _TestTaskRepository extends TaskRepository {
  _TestTaskRepository(this.tasks);

  final Map<String, Task> tasks;
  TaskUpdate? lastUpdate;

  @override
  Future<Task?> findById(String id) async => tasks[id];

  @override
  Future<Task?> findByTaskId(String taskId) async {
    for (final task in tasks.values) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  @override
  Stream<Task?> watchTaskById(String id) => Stream.value(tasks[id]);

  @override
  Future<void> updateTask(String taskId, TaskUpdate payload) async {
    final existing = tasks[taskId];
    if (existing == null) return;
    final parentId = payload.clearParent == true
        ? null
        : payload.parentId ?? existing.parentId;
    tasks[taskId] = Task(
      id: existing.id,

      title: existing.title,
      status: existing.status,
      dueAt: payload.dueAt ?? existing.dueAt,
      startedAt: existing.startedAt,
      endedAt: existing.endedAt,
      createdAt: existing.createdAt,
      updatedAt: existing.updatedAt,
      parentId: parentId,
      sortIndex: payload.sortIndex ?? existing.sortIndex,
      tags: existing.tags,
      templateLockCount: existing.templateLockCount,
      seedSlug: existing.seedSlug,
      allowInstantComplete: existing.allowInstantComplete,
      description: existing.description,
      logs: existing.logs,
    );
    lastUpdate = payload;
  }

  @override
  Future<List<Task>> listChildren(String parentId) async => tasks.values
      .where((task) => task.parentId == parentId)
      .toList(growable: false);

  @override
  Future<List<Task>> listChildrenIncludingTrashed(String parentId) async =>
      tasks.values
          .where((task) => task.parentId == parentId)
          .toList(growable: false);

  @override
  Future<List<Task>> listAll() async => tasks.values.toList(growable: false);

  // ===== Unused methods throw to surface accidental calls =====
  @override
  Stream<List<Task>> watchSection(TaskSection section) =>
      throw UnimplementedError();

  @override
  Stream<TaskTreeNode> watchTaskTree(String rootTaskId) =>
      throw UnimplementedError();

  @override
  Stream<List<Task>> watchInbox() => throw UnimplementedError();

  @override
  Stream<List<Task>> watchProjects() => throw UnimplementedError();

  @override
  Stream<List<Task>> watchQuickTasks() => throw UnimplementedError();

  @override
  Stream<List<Task>> watchMilestones(String projectId) =>
      throw UnimplementedError();

  @override
  Stream<List<Task>> watchTasksByProjectId(String projectId) =>
      throw UnimplementedError();

  @override
  Stream<List<Task>> watchTasksByMilestoneId(String milestoneId) =>
      throw UnimplementedError();

  @override
  Future<List<Task>> listTasksByMilestoneId(String milestoneId) async =>
      throw UnimplementedError();

  @override
  Stream<List<Task>> watchInboxFiltered({
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) => throw UnimplementedError();

  @override
  Future<Task> createTask(TaskDraft draft) => throw UnimplementedError();

  @override
  Future<Task> createTaskWithId(
    TaskDraft draft,
    String taskId,
    DateTime createdAt,
    DateTime updatedAt,
  ) => throw UnimplementedError();

  @override
  Future<void> moveTask({
    required String taskId,
    required String? targetParentId,
    required TaskSection targetSection,
    required double sortIndex,
    DateTime? dueAt,
  }) => throw UnimplementedError();

  @override
  Future<void> markStatus({
    required String taskId,
    required TaskStatus status,
  }) => throw UnimplementedError();

  @override
  Future<void> archiveTask(String taskId) => throw UnimplementedError();

  @override
  Future<void> softDelete(String taskId) => throw UnimplementedError();

  @override
  Future<int> clearAllTrashedTasks() => throw UnimplementedError();

  @override
  Future<int> purgeObsolete(DateTime olderThan) => throw UnimplementedError();

  @override
  Future<void> adjustTemplateLock({
    required String taskId,
    required int delta,
  }) => throw UnimplementedError();

  @override
  Future<Task?> findBySlug(String slug) => throw UnimplementedError();

  @override
  Future<List<Task>> listRoots() => throw UnimplementedError();

  @override
  Future<void> upsertTasks(List<Task> tasks) => throw UnimplementedError();

  @override
  Future<List<Task>> searchByTitle(
    String query, {
    TaskStatus? status,
    int? limit,
  }) => throw UnimplementedError();

  @override
  Future<void> batchUpdate(Map<String, TaskUpdate> updates) =>
      throw UnimplementedError();

  @override
  Future<List<Task>> listSectionTasks(TaskSection section) =>
      throw UnimplementedError();

  @override
  Future<List<Task>> listCompletedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) => throw UnimplementedError();

  @override
  Future<List<Task>> listArchivedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) => throw UnimplementedError();

  @override
  Future<int> countCompletedTasks() => throw UnimplementedError();

  @override
  Future<int> countArchivedTasks() => throw UnimplementedError();

  @override
  Future<List<Task>> listTrashedTasks({
    required int limit,
    required int offset,
    String? contextTag,
    String? priorityTag,
    String? urgencyTag,
    String? importanceTag,
    String? projectId,
    String? milestoneId,
    bool? showNoProject,
  }) => throw UnimplementedError();

  @override
  Future<int> countTrashedTasks() => throw UnimplementedError();

  Future<void> setTaskProjectAndMilestoneIsarId(
    int taskId,
    int? projectIsarId,
    int? milestoneIsarId,
  ) async {
    // 测试中不需要实现，因为内存实现不维护 Isar ID 关系
  }
}

class _StubMetricRepository implements MetricRepository {
  @override
  Future<MetricSnapshot> recompute({
    required Iterable<Task> tasks,
    required int totalFocusMinutes,
  }) async => MetricSnapshot(
    id: '1',
    totalCompletedTasks: 0,
    totalFocusMinutes: 0,
    pendingTasks: 0,
    pendingTodayTasks: 0,
    calculatedAt: DateTime.now(),
  );

  @override
  Stream<MetricSnapshot?> watchLatest() => const Stream.empty();

  @override
  Future<void> invalidate() async {}
}

class _StubFocusSessionRepository implements FocusSessionRepository {
  @override
  Future<FocusSession> startSession({
    required String taskId,
    int? estimateMinutes,
    bool alarmEnabled = false,
  }) => throw UnimplementedError();

  @override
  Future<void> endSession({
    required String sessionId,
    required int actualMinutes,
    String? transferToTaskId,
    String? reflectionNote,
  }) => throw UnimplementedError();

  @override
  Stream<FocusSession?> watchActiveSession(String taskId) =>
      const Stream.empty();

  @override
  Future<List<FocusSession>> listRecentSessions({
    required String taskId,
    int limit = 10,
  }) => throw UnimplementedError();

  @override
  Future<int> totalMinutesForTask(String taskId) async => 0;

  @override
  Future<Map<String, int>> totalMinutesForTasks(List<String> taskIds) async {
    return {for (final taskId in taskIds) taskId: 0};
  }

  @override
  Future<int> totalMinutesOverall() async => 0;

  @override
  Future<FocusSession?> findById(String sessionId) =>
      throw UnimplementedError();
}
