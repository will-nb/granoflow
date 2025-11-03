import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/providers/tasks_section_drag_provider.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/views/task_section_panel.dart';

class _FakeTaskService extends Fake implements TaskService {}

Task _createTask({required int id}) {
  return Task(
    id: id,
    taskId: 'task-$id',
    title: 'Task $id',
    status: TaskStatus.pending,
    sortIndex: id.toDouble(),
    dueAt: DateTime(2025, 1, id),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    tags: const [],
    templateLockCount: 0,
    logs: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskSectionPanel renders task title when tasks exist', (tester) async {
    final task = _createTask(id: 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
          taskTreeProvider.overrideWithProvider((taskId) {
            return StreamProvider<TaskTreeNode>((ref) {
              final nodeTask = task.copyWith(id: taskId, taskId: 'task-$taskId');
              return Stream.value(
                TaskTreeNode(task: nodeTask, children: const <TaskTreeNode>[]),
              );
            });
          }),
          urgencyTagOptionsProvider.overrideWith((ref) async => const []),
          importanceTagOptionsProvider.overrideWith((ref) async => const []),
          executionTagOptionsProvider.overrideWith((ref) async => const []),
          contextTagOptionsProvider.overrideWith((ref) async => const []),
          // Mock the new async providers for TasksSectionTaskList
          tasksSectionTaskLevelMapProvider.overrideWith(
            (ref, section) async => {task.id: 1},
          ),
          tasksSectionTaskChildrenMapProvider.overrideWith(
            (ref, section) async => <int, Set<int>>{},
          ),
          tasksSectionExpandedTaskIdProvider.overrideWith(
            (ref, section) => <int>{},
          ),
          tasksSectionDragProvider.overrideWith(
            (ref, section) => TasksSectionDragNotifier(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TaskSectionPanel(
              section: TaskSection.today,
              title: 'Today',
              editMode: false,
              onQuickAdd: () {},
              tasks: <Task>[task],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(); // Pump again to allow async providers to resolve

    expect(find.text('Task 1'), findsOneWidget);
  });
}

