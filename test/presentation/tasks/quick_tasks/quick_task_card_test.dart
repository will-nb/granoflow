import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/quick_tasks/quick_task_card.dart';

void main() {
  testWidgets('QuickTaskCard renders execution icon for timed tasks', (
    tester,
  ) async {
    final task = Task(
      id: '1',

      title: 'Quick timing task',
      status: TaskStatus.pending,
      createdAt: DateTime(2024, 2, 1),
      updatedAt: DateTime(2024, 2, 1),
      dueAt: DateTime(2024, 2, 2),
      tags: const <String>['#timed'],
      sortIndex: 0,
      templateLockCount: 0,
      allowInstantComplete: false,
      logs: const <TaskLogEntry>[],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskTreeProvider.overrideWithProvider((taskId) {
            return StreamProvider<TaskTreeNode>((ref) {
              if (taskId == task.id) {
                return Stream.value(
                  TaskTreeNode(task: task, children: const <TaskTreeNode>[]),
                );
              }
              final fallback = task.copyWith(id: taskId);
              return Stream.value(
                TaskTreeNode(task: fallback, children: const <TaskTreeNode>[]),
              );
            });
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: QuickTaskCard(task: task)),
        ),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.schedule), findsWidgets);
  });
}
