import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/views/task_tree_tile.dart';
import 'package:granoflow/presentation/tasks/widgets/parent_task_header.dart';
import 'package:granoflow/presentation/tasks/widgets/all_children_list.dart';
import 'package:granoflow/presentation/tasks/views/task_section_list.dart';

class _FakeTaskService extends Fake implements TaskService {}

Task _createTask({required int id, int? parentId, DateTime? dueAt}) {
  // 如果没有指定 dueAt，使用同一个日期，确保父子任务在同一区域
  final taskDueAt = dueAt ?? DateTime(2025, 1, 15); // 使用固定日期，确保在同一区域
  return Task(
    id: id,
    taskId: 'task-$id',
    title: 'Task $id',
    status: TaskStatus.pending,
    dueAt: taskDueAt,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    parentId: parentId,
    sortIndex: id.toDouble(),
    tags: const [],
    templateLockCount: 0,
    allowInstantComplete: false,
    logs: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskTreeTile renders root and child tasks', (tester) async {
    // 使用今天作为日期，确保任务在 TaskSection.today 区域
    final today = DateTime.now();
    final root = _createTask(id: 1, dueAt: today);
    final child = _createTask(id: 2, parentId: 1, dueAt: today);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
          parentTaskChildrenCountProvider.overrideWith((ref, parentId) async => 1),
          parentTaskChildrenProvider.overrideWith((ref, parentId) async => [child]),
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
          taskProjectHierarchyProvider.overrideWith((ref, taskId) => Stream.value(null)),
          parentTaskProvider.overrideWith((ref, parentId) async {
            if (parentId == root.id) return null;
            return null;
          }),
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
    await tester.pumpAndSettle();

    // 展开父任务的"显示全部子任务"
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    await tester.tap(find.text(l10n.showAllSubtasks));
    await tester.pumpAndSettle();

    expect(find.text('Task 2'), findsOneWidget);
  });
}

