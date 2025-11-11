import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_hierarchy_service.dart';
import 'package:granoflow/core/services/sort_index_service.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/presentation/common/task_list/task_list_insertion_handler.dart';
import 'package:granoflow/presentation/common/task_list/inbox_task_list_config.dart';
import 'package:granoflow/presentation/common/task_list/tasks_section_task_list_config.dart';

class _FakeTaskHierarchyService extends Fake implements TaskHierarchyService {
  bool moveToParentCalled = false;
  String? moveToParentTaskId;
  String? moveToParentParentId;
  double? moveToParentSortIndex;
  DateTime? moveToParentDueDate;
  bool? moveToParentClearParent;
  Exception? moveToParentException;

  @override
  Future<void> moveToParent({
    required String taskId,
    required String? parentId,
    required double sortIndex,
    DateTime? dueDate,
    bool clearParent = false,
  }) async {
    moveToParentCalled = true;
    moveToParentTaskId = taskId;
    moveToParentParentId = parentId;
    moveToParentSortIndex = sortIndex;
    moveToParentDueDate = dueDate;
    moveToParentClearParent = clearParent;
    if (moveToParentException != null) {
      throw moveToParentException!;
    }
  }
}

class _FakeTaskRepository extends Fake implements TaskRepository {
  final List<Task> allTasks;
  final List<Task> inboxTasks;

  _FakeTaskRepository({this.allTasks = const [], this.inboxTasks = const []});

  @override
  Future<List<Task>> listAll() async => allTasks;

  @override
  Stream<List<Task>> watchInbox() => Stream.value(inboxTasks);
}

class _FakeSortIndexService extends Fake implements SortIndexService {
  bool reorderTasksForInboxCalled = false;
  List<Task>? reorderTasksForInboxTasks;
  bool reorderTasksForSameDateCalled = false;
  List<Task>? reorderTasksForSameDateAllTasks;
  DateTime? reorderTasksForSameDateTargetDate;

  @override
  Future<void> reorderTasksForInbox({
    required List<Task> tasks,
    double start = 1024,
    double step = 1024,
  }) async {
    reorderTasksForInboxCalled = true;
    reorderTasksForInboxTasks = tasks;
  }

  @override
  Future<void> reorderTasksForSameDate({
    required List<Task> allTasks,
    required DateTime? targetDate,
    double start = 1024,
    double step = 1024,
  }) async {
    reorderTasksForSameDateCalled = true;
    reorderTasksForSameDateAllTasks = allTasks;
    reorderTasksForSameDateTargetDate = targetDate;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskListInsertionHandler', () {
    late _FakeTaskHierarchyService fakeTaskHierarchyService;
    late _FakeTaskRepository fakeTaskRepository;
    late _FakeSortIndexService fakeSortIndexService;

    setUp(() {
      fakeTaskHierarchyService = _FakeTaskHierarchyService();
      fakeTaskRepository = _FakeTaskRepository();
      fakeSortIndexService = _FakeSortIndexService();
    });

    Task _createTask({
      required String id,
      String? parentId,
      double sortIndex = 1000,
      DateTime? dueAt,
    }) {
      return Task(
        id: id,

        title: 'Task $id',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        parentId: parentId,
        sortIndex: sortIndex,
        dueAt: dueAt ?? DateTime(2025, 1, 1),
        tags: const [],
      );
    }

    group('handleInsertionDrop', () {
      testWidgets('should handle first insertion (top)', (tester) async {
        final draggedTask = _createTask(id: '1');
        final beforeTask = _createTask(id: '2');
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          null, // beforeTask
          beforeTask, // afterTask
          'first',
          config,
          testRef!,
        );

        expect(fakeTaskHierarchyService.moveToParentCalled, true);
        expect(fakeTaskHierarchyService.moveToParentTaskId, '1');
        expect(fakeTaskHierarchyService.moveToParentParentId, null);
        expect(fakeTaskHierarchyService.moveToParentClearParent, true);
        expect(result.success, true);
      });

      testWidgets('should handle last insertion (bottom)', (tester) async {
        final draggedTask = _createTask(id: '1');
        final beforeTask = _createTask(id: '2');
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          beforeTask, // beforeTask
          null, // afterTask
          'last',
          config,
          testRef!,
        );

        expect(fakeTaskHierarchyService.moveToParentCalled, true);
        expect(fakeTaskHierarchyService.moveToParentTaskId, '1');
        expect(
          fakeTaskHierarchyService.moveToParentParentId,
          beforeTask.parentId,
        );
        // clearParent 只有在 parentId == null 时才为 true（见 handleInsertionDrop 的 clearParent: aboveTaskParentId == null）
        expect(
          fakeTaskHierarchyService.moveToParentClearParent,
          beforeTask.parentId == null,
        );
        expect(result.success, true);
      });

      testWidgets('should handle between insertion', (tester) async {
        final draggedTask = _createTask(id: '1');
        final beforeTask = _createTask(id: '2', sortIndex: 1000);
        final afterTask = _createTask(id: '3', sortIndex: 2000);
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          beforeTask,
          afterTask,
          'between',
          config,
          testRef!,
        );

        expect(fakeTaskHierarchyService.moveToParentCalled, true);
        expect(fakeTaskHierarchyService.moveToParentTaskId, '1');
        expect(
          fakeTaskHierarchyService.moveToParentParentId,
          beforeTask.parentId,
        );
        // clearParent 只有在 parentId == null 时才为 true
        expect(
          fakeTaskHierarchyService.moveToParentClearParent,
          beforeTask.parentId == null,
        );
        expect(result.success, true);
      });

      testWidgets('should handle subtask promotion (Inbox)', (tester) async {
        final draggedTask = _createTask(id: '1', parentId: '99');
        final beforeTask = _createTask(id: '2');
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          null,
          beforeTask,
          'first',
          config,
          testRef!,
        );

        expect(fakeTaskHierarchyService.moveToParentCalled, true);
        expect(fakeTaskHierarchyService.moveToParentTaskId, '1');
        expect(fakeTaskHierarchyService.moveToParentParentId, null);
        expect(fakeTaskHierarchyService.moveToParentClearParent, true);
        expect(result.success, true);
      });

      testWidgets('should call reorderTasks for Inbox config', (tester) async {
        final draggedTask = _createTask(id: '1');
        final beforeTask = _createTask(id: '2');
        final config = InboxTaskListConfig();
        final inboxTasks = [_createTask(id: '1'), _createTask(id: '2')];
        WidgetRef? testRef;

        fakeTaskRepository = _FakeTaskRepository(
          allTasks: [],
          inboxTasks: inboxTasks,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          null,
          beforeTask,
          'first',
          config,
          testRef!,
        );

        expect(fakeSortIndexService.reorderTasksForInboxCalled, true);
        expect(fakeSortIndexService.reorderTasksForInboxTasks, inboxTasks);
      });

      testWidgets('should handle Tasks config with cross-section drag', (
        tester,
      ) async {
        final now = DateTime.now();
        final draggedTask = _createTask(id: '1', dueAt: now);
        final beforeTask = _createTask(
          id: '2',
          dueAt: TaskSectionUtils.getSectionEndTime(
            TaskSection.tomorrow,
            now: now,
          ),
        );
        final config = TasksSectionTaskListConfig(TaskSection.tomorrow);
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          null,
          beforeTask,
          'first',
          config,
          testRef!,
        );

        // 应该使用目标 section 的结束时间作为 dueDate
        expect(fakeTaskHierarchyService.moveToParentCalled, true);
        expect(fakeTaskHierarchyService.moveToParentTaskId, '1');
        expect(fakeTaskHierarchyService.moveToParentParentId, null);
        expect(fakeTaskHierarchyService.moveToParentDueDate, isNotNull);
        expect(fakeTaskHierarchyService.moveToParentClearParent, true);
        expect(result.success, true);
      });

      testWidgets('should call reorderTasksForSameDate for Tasks config', (
        tester,
      ) async {
        final draggedTask = _createTask(id: '1');
        final beforeTask = _createTask(id: '2');
        final config = TasksSectionTaskListConfig(TaskSection.today);
        final allTasks = [_createTask(id: '1'), _createTask(id: '2')];
        WidgetRef? testRef;

        fakeTaskRepository = _FakeTaskRepository(allTasks: allTasks);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          null,
          beforeTask,
          'first',
          config,
          testRef!,
        );

        expect(fakeSortIndexService.reorderTasksForSameDateCalled, true);
        expect(fakeSortIndexService.reorderTasksForSameDateAllTasks, allTasks);
        expect(
          fakeSortIndexService.reorderTasksForSameDateTargetDate,
          isNotNull,
        );
      });

      testWidgets('should return blocked result on error', (tester) async {
        final draggedTask = _createTask(id: '1');
        final beforeTask = _createTask(id: '2');
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        fakeTaskHierarchyService.moveToParentException = Exception(
          'Service error',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          null,
          beforeTask,
          'first',
          config,
          testRef!,
        );

        expect(result.success, false);
        expect(result.blockReasonKey, 'taskMoveBlockedUnknown');
      });

      testWidgets('should handle between insertion with only beforeTask', (
        tester,
      ) async {
        final draggedTask = _createTask(id: '1');
        final beforeTask = _createTask(id: '2');
        final config = InboxTaskListConfig();
        WidgetRef? testRef;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              taskHierarchyServiceProvider.overrideWith(
                (ref) async => fakeTaskHierarchyService,
              ),
              taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
              sortIndexServiceProvider.overrideWith((ref) async => fakeSortIndexService),
            ],
            child: Consumer(
              builder: (context, ref, child) {
                testRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final result = await TaskListInsertionHandler.handleInsertionDrop(
          draggedTask,
          beforeTask,
          null, // afterTask 为 null
          'between',
          config,
          testRef!,
        );

        expect(fakeTaskHierarchyService.moveToParentCalled, true);
        expect(fakeTaskHierarchyService.moveToParentTaskId, '1');
        expect(
          fakeTaskHierarchyService.moveToParentParentId,
          beforeTask.parentId,
        );
        // clearParent 只有在 parentId == null 时才为 true
        expect(
          fakeTaskHierarchyService.moveToParentClearParent,
          beforeTask.parentId == null,
        );
        expect(result.success, true);
      });

      testWidgets(
        'should handle between insertion with neither beforeTask nor afterTask',
        (tester) async {
          final draggedTask = _createTask(id: '1');
          final config = InboxTaskListConfig();
          WidgetRef? testRef;

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                taskHierarchyServiceProvider.overrideWith(
                (ref) async =>
                  fakeTaskHierarchyService,
                ),
                taskRepositoryProvider.overrideWith((ref) async => fakeTaskRepository),
                sortIndexServiceProvider.overrideWith(
                  (ref) async => fakeSortIndexService,
                ),
              ],
              child: Consumer(
                builder: (context, ref, child) {
                  testRef = ref;
                  return const SizedBox.shrink();
                },
              ),
            ),
          );

          final result = await TaskListInsertionHandler.handleInsertionDrop(
            draggedTask,
            null,
            null,
            'between',
            config,
            testRef!,
          );

          // 应该使用默认 sortIndex
          expect(fakeTaskHierarchyService.moveToParentCalled, true);
          expect(fakeTaskHierarchyService.moveToParentTaskId, '1');
          expect(fakeTaskHierarchyService.moveToParentParentId, null);
          expect(
            fakeTaskHierarchyService.moveToParentSortIndex,
            0.0,
          ); // DEFAULT_SORT_INDEX
          expect(fakeTaskHierarchyService.moveToParentClearParent, true);
          expect(result.success, true);
        },
      );
    });
  });
}
