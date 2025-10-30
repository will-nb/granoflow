import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/projects_dashboard.dart';

class _FakeTaskEditActions extends TaskEditActionsNotifier {
  @override
  Future<void> build() async {}

  @override
  Future<void> archive(int taskId) async {}

  @override
  Future<void> addSubtask({required int parentId, required String title}) async {}

  @override
  Future<void> editTitle({required int taskId, required String title}) async {}
}

class _FakeTaskService extends Fake implements TaskService {}

void main() {
  testWidgets('ProjectsDashboard renders project list', (tester) async {
    final project = Task(
      id: 1,
      taskId: 'project-1',
      title: 'Refactor App',
      status: TaskStatus.pending,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      dueAt: DateTime(2025, 2, 1),
      tags: const <String>['#urgent'],
      sortIndex: 0,
      templateLockCount: 0,
      allowInstantComplete: false,
      logs: const <TaskLogEntry>[],
      taskKind: TaskKind.project,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectsProvider.overrideWith((ref) => Stream<List<Task>>.value([project])),
          projectMilestonesProvider.overrideWithProvider((projectId) {
            return StreamProvider<List<Task>>((ref) {
              return Stream.value(const <Task>[]);
            });
          }),
          quickTasksProvider.overrideWith((ref) => Stream<List<Task>>.value(const <Task>[])),
          projectsExpandedTaskIdProvider.overrideWith((ref) => null),
          taskEditActionsNotifierProvider.overrideWith(() => _FakeTaskEditActions()),
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProjectsDashboard()),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Refactor App'), findsOneWidget);
  });
}

