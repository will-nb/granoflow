import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/milestones/milestone_card.dart';

class _FakeTaskService extends Fake implements TaskService {}

Task _createTask() {
  return Task(
    id: 1,
    taskId: 'milestone-1',
    title: 'Launch Beta',
    status: TaskStatus.pending,
    dueAt: DateTime(2025, 1, 2),
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    description: 'Prepare assets and marketing copy.',
    tags: const <String>['#urgent'],
    sortIndex: 0,
    templateLockCount: 0,
    allowInstantComplete: false,
    logs: const <TaskLogEntry>[],
    taskKind: TaskKind.milestone,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MilestoneCard renders milestone details', (tester) async {
    final task = _createTask();

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
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MilestoneCard(milestone: task)),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Launch Beta'), findsOneWidget);
    expect(find.textContaining('Prepare assets and marketing copy.'), findsOneWidget);
  });
}

