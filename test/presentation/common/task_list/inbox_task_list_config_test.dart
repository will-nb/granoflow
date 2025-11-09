import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/inbox_drag_provider.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/sort_index_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/data/repositories/task_repository.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/common/task_list/inbox_task_list_config.dart';

class _FakeTaskRepository extends Fake implements TaskRepository {
  final List<Task> inboxTasks;

  _FakeTaskRepository(this.inboxTasks);

  @override
  Stream<List<Task>> watchInbox() => Stream.value(inboxTasks);
}

class _FakeSortIndexService extends Fake implements SortIndexService {
  bool reorderTasksForInboxCalled = false;

  @override
  Future<void> reorderTasksForInbox({
    required List<Task> tasks,
    double start = 1024,
    double step = 1024,
  }) async {
    reorderTasksForInboxCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InboxTaskListConfig', () {
    test('should return correct dragProvider', () {
      final config = InboxTaskListConfig();
      expect(config.dragProvider, inboxDragProvider);
    });

    testWidgets('should return correct expandedProvider', (tester) async {
      final config = InboxTaskListConfig();
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
      expect(expandedProvider, inboxExpandedTaskIdProvider);
    });

    testWidgets('should return correct levelMapProvider', (tester) async {
      final config = InboxTaskListConfig();
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
      expect(levelMapProvider, inboxTaskLevelMapProvider);
    });

    testWidgets('should return correct childrenMapProvider', (tester) async {
      final config = InboxTaskListConfig();
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
      expect(childrenMapProvider, inboxTaskChildrenMapProvider);
    });

    testWidgets('should build InboxTaskTile', (tester) async {
      final config = InboxTaskListConfig();
      final task = Task(
        id: 1,

        title: 'Test Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        sortIndex: 1000,
        tags: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inboxTaskLevelMapProvider.overrideWith(
              (ref) async => <int, int>{1: 1},
            ),
            inboxTaskChildrenMapProvider.overrideWith(
              (ref) async => <int, Set<int>>{},
            ),
            contextTagOptionsProvider.overrideWith((ref) async => const []),
            urgencyTagOptionsProvider.overrideWith((ref) async => const []),
            importanceTagOptionsProvider.overrideWith((ref) async => const []),
            executionTagOptionsProvider.overrideWith((ref) async => const []),
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

    testWidgets('should call reorderTasksForInbox in reorderTasks', (
      tester,
    ) async {
      final config = InboxTaskListConfig();
      final tasks = [
        Task(
          id: 1,

          title: 'Task 1',
          status: TaskStatus.inbox,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          sortIndex: 1000,
          tags: const [],
        ),
      ];
      final fakeTaskRepository = _FakeTaskRepository(tasks);
      final fakeSortIndexService = _FakeSortIndexService();
      WidgetRef? testRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskRepositoryProvider.overrideWithValue(fakeTaskRepository),
            sortIndexServiceProvider.overrideWithValue(fakeSortIndexService),
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
        targetDate: null,
      );

      expect(fakeSortIndexService.reorderTasksForInboxCalled, true);
    });

    test('should return null for handleDueDate (no date change)', () {
      final config = InboxTaskListConfig();
      final task = Task(
        id: 1,

        title: 'Test Task',
        status: TaskStatus.inbox,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        dueAt: DateTime(2025, 1, 10),
        sortIndex: 1000,
        tags: const [],
      );

      final result = config.handleDueDate(
        section: null,
        beforeTask: null,
        afterTask: null,
        draggedTask: task,
      );

      expect(result, null);
    });

    test('should return null for section', () {
      final config = InboxTaskListConfig();
      expect(config.section, null);
    });

    test('should return correct pageName', () {
      final config = InboxTaskListConfig();
      expect(config.pageName, 'Inbox');
    });

    testWidgets('should return correct dragNotifier', (tester) async {
      final config = InboxTaskListConfig();
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
      // 验证是 InboxDragNotifier 类型
      expect(dragNotifier, isA<InboxDragNotifier>());
    });
  });
}
