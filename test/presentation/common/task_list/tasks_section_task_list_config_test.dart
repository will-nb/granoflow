import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/providers/tasks_drag_provider.dart';
import 'package:granoflow/core/services/sort_index_service.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/common/task_list/tasks_section_task_list_config.dart';

class _FakeTaskRepository extends Fake implements TaskRepository {
  final List<Task> allTasks;

  _FakeTaskRepository(this.allTasks);

  @override
  Future<List<Task>> listAll() async => allTasks;
}

class _FakeSortIndexService extends Fake implements SortIndexService {
  bool reorderTasksForSameDateCalled = false;
  DateTime? receivedTargetDate;

  @override
  Future<void> reorderTasksForSameDate({
    required List<Task> allTasks,
    required DateTime? targetDate,
    double start = 1024,
    double step = 1024,
  }) async {
    reorderTasksForSameDateCalled = true;
    receivedTargetDate = targetDate;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TasksSectionTaskListConfig', () {
    test('should return correct dragProvider', () {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      expect(config.dragProvider, tasksDragProvider);
    });

    testWidgets('should return correct expandedProvider for section', (
      tester,
    ) async {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      WidgetRef? testRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              testRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final expandedProvider = config.getExpandedProvider(testRef!);
      expect(
        expandedProvider,
        tasksSectionExpandedTaskIdProvider(TaskSection.today),
      );
    });

    testWidgets('should return correct levelMapProvider for section', (
      tester,
    ) async {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      WidgetRef? testRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              testRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final levelMapProvider = config.getLevelMapProvider(testRef!);
      // 层级功能已移除，getLevelMapProvider 现在返回 FutureProvider
      expect(levelMapProvider, isA<FutureProvider<Map<String, int>>>());
    });

    testWidgets('should return correct childrenMapProvider for section', (
      tester,
    ) async {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      WidgetRef? testRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              testRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final childrenMapProvider = config.getChildrenMapProvider(testRef!);
      // 层级功能已移除，getChildrenMapProvider 现在返回 FutureProvider
      expect(childrenMapProvider, isA<FutureProvider<Map<String, Set<String>>>>());
    });

    testWidgets('should build TasksSectionTaskTile', (tester) async {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      final task = Task(
        id: '1',

        title: 'Test Task',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        dueAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // 层级功能已移除，不再需要这些 provider
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: config.buildTaskTile(
                task: task,
                key: const ValueKey('test'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test Task'), findsOneWidget);
    });

    testWidgets('should call reorderTasksForSameDate in reorderTasks', (
      tester,
    ) async {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      final tasks = [
        Task(
          id: '1',

          title: 'Task 1',
          status: TaskStatus.pending,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          dueAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const [],
        ),
      ];
      final fakeTaskRepository = _FakeTaskRepository(tasks);
      final fakeSortIndexService = _FakeSortIndexService();
      final targetDate = DateTime(2025, 1, 1);
      WidgetRef? testRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      await config.reorderTasks(
        ref: testRef!,
        allTasks: tasks,
        targetDate: targetDate,
      );

      expect(fakeSortIndexService.reorderTasksForSameDateCalled, true);
      expect(fakeSortIndexService.receivedTargetDate, targetDate);
    });

    test('should return same date for same-section drag', () {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      final now = DateTime.now();
      final draggedTask = Task(
        id: '1',

        title: 'Task 1',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        dueAt: now, // today
        sortIndex: 1000,
        tags: const [],
      );
      final beforeTask = Task(
        id: '2',

        title: 'Task 2',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        dueAt: now, // today
        sortIndex: 2000,
        tags: const [],
      );

      final result = config.handleDueDate(
        section: TaskSection.today,
        beforeTask: beforeTask,
        afterTask: null,
        draggedTask: draggedTask,
      );

      // 同区域拖拽应该返回目标任务的 dueAt
      expect(result, beforeTask.dueAt);
    });

    test('should return section end time for cross-section drag', () {
      final config = TasksSectionTaskListConfig(TaskSection.tomorrow);
      final now = DateTime.now();
      final draggedTask = Task(
        id: '1',

        title: 'Task 1',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        dueAt: now, // today
        sortIndex: 1000,
        tags: const [],
      );
      final beforeTask = Task(
        id: '2',

        title: 'Task 2',
        status: TaskStatus.pending,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        dueAt: now.add(const Duration(days: 1)), // tomorrow
        sortIndex: 2000,
        tags: const [],
      );

      final result = config.handleDueDate(
        section: TaskSection.tomorrow,
        beforeTask: beforeTask,
        afterTask: null,
        draggedTask: draggedTask,
      );

      // 跨区域拖拽应该返回目标区域的结束时间
      final expectedEndTime = TaskSectionUtils.getSectionEndTime(
        TaskSection.tomorrow,
        now: now,
      );
      expect(result, expectedEndTime);
    });

    test('should return correct section', () {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      expect(config.section, TaskSection.today);
    });

    test('should return correct pageName', () {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      expect(config.pageName, 'Tasks');
    });

    testWidgets('should return correct dragNotifier', (tester) async {
      final config = TasksSectionTaskListConfig(TaskSection.today);
      WidgetRef? testRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              testRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final dragNotifier = config.getDragNotifier(testRef!);
      expect(dragNotifier, isNotNull);
      // 验证是 TasksDragNotifier 类型
      expect(dragNotifier, isA<TasksDragNotifier>());
    });
  });
}
