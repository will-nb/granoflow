import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/views/task_tree_tile.dart';

class _FakeTaskService extends Fake implements TaskService {}

Task _createTask({required int id, int? parentId}) {
  return Task(
    id: id,
    taskId: 'task-$id',
    title: 'Task $id',
    status: TaskStatus.pending,
    dueAt: DateTime(2025, 1, id),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    parentId: parentId,
    sortIndex: id.toDouble(),
    tags: const [],
    templateLockCount: 0,
    allowInstantComplete: false,
    logs: const [],
    taskKind: TaskKind.regular,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskTreeTile renders root and child tasks', (tester) async {
    final root = _createTask(id: 1);
    final child = _createTask(id: 2, parentId: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
          taskTreeProvider.overrideWithProvider((taskId) {
            return StreamProvider<TaskTreeNode>((ref) {
              if (taskId == root.id) {
                return Stream.value(
                  TaskTreeNode(
                    task: root,
                    children: <TaskTreeNode>[
                      TaskTreeNode(task: child, children: const <TaskTreeNode>[]),
                    ],
                  ),
                );
              }
              return Stream.value(
                TaskTreeNode(
                  task: child.copyWith(id: taskId, taskId: 'task-$taskId'),
                  children: const <TaskTreeNode>[],
                ),
              );
            });
          }),
          urgencyTagOptionsProvider.overrideWith((ref) async => const []),
          importanceTagOptionsProvider.overrideWith((ref) async => const []),
          executionTagOptionsProvider.overrideWith((ref) async => const []),
          contextTagOptionsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TaskTreeTile(
              section: TaskSection.today,
              rootTask: root,
              editMode: false,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Task 1'), findsOneWidget);

    await tester.tap(find.text('Task 1'));
    await tester.pumpAndSettle();

    expect(find.text('Task 2'), findsOneWidget);
  });
}

