import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/core/utils/task_section_utils.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/views/tasks_section_task_list.dart';

class _FakeTaskService extends Fake implements TaskService {}

Task _createTask({required int id, DateTime? dueAt}) {
  return Task(
    id: id,
    taskId: 'task-$id',
    title: 'Task $id',
    status: TaskStatus.pending,
    dueAt: dueAt ?? DateTime(2025, 1, 1),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    parentId: null,
    sortIndex: 1000,
    tags: const [],
  );
}

void main() {
  group('TasksSectionTaskList Widget Updates', () {
    testWidgets('should initialize without errors', (tester) async {
      final tasks = [_createTask(id: 1)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.today)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, int>{1: 1}),
            tasksSectionTaskChildrenMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.today,
                tasks: tasks,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Task 1'), findsOneWidget);
    });

    testWidgets('should handle widget update when tasks change', (tester) async {
      final tasks1 = [_createTask(id: 1)];
      final tasks2 = [_createTask(id: 1), _createTask(id: 2)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.today)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, int>{1: 1, 2: 1}),
            tasksSectionTaskChildrenMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.today,
                tasks: tasks1,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsNothing);

      // 更新 tasks
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.today)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, int>{1: 1, 2: 1}),
            tasksSectionTaskChildrenMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.today,
                tasks: tasks2,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });

    testWidgets('should update config when section changes', (tester) async {
      final tasks = [_createTask(id: 1)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.today)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, int>{1: 1}),
            tasksSectionTaskChildrenMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.today,
                tasks: tasks,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 更改 section（这应该不会导致 late final 错误）
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.tomorrow)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.tomorrow)
                .overrideWith((ref) async => <int, int>{1: 1}),
            tasksSectionTaskChildrenMapProvider(TaskSection.tomorrow)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.tomorrow,
                tasks: tasks,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // 应该不会崩溃
      expect(find.text('Task 1'), findsOneWidget);
    });

    testWidgets('should handle empty task list', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.today)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, int>{}),
            tasksSectionTaskChildrenMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.today,
                tasks: [],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // 空列表应该显示 SizedBox.shrink()，不渲染任何内容
      expect(find.byType(TasksSectionTaskList), findsOneWidget);
    });

    testWidgets('should handle widget rebuild after drag operation', (tester) async {
      final tasks = [_createTask(id: 1), _createTask(id: 2)];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.today)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, int>{1: 1, 2: 1}),
            tasksSectionTaskChildrenMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.today,
                tasks: tasks,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);

      // 模拟拖拽后的重建（tasks 顺序改变）
      final reorderedTasks = [_createTask(id: 2), _createTask(id: 1)];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
            tasksSectionExpandedTaskIdProvider(TaskSection.today)
                .overrideWith((ref) => const <int>{}),
            tasksSectionTaskLevelMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, int>{1: 1, 2: 1}),
            tasksSectionTaskChildrenMapProvider(TaskSection.today)
                .overrideWith((ref) async => <int, Set<int>>{}),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TasksSectionTaskList(
                section: TaskSection.today,
                tasks: reorderedTasks,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // 应该不会崩溃，并且能正常显示
      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });
  });
}

