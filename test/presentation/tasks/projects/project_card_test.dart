import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/project_card.dart';

class _FakeTaskService extends Fake implements TaskService {}

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

void main() {
  testWidgets('ProjectCard shows project title', (tester) async {
    final project = Task(
      id: 1,
      taskId: 'project-1',
      title: 'Landing Page Revamp',
      status: TaskStatus.pending,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      dueAt: DateTime(2025, 1, 15),
      tags: const <String>['#important'],
      sortIndex: 0,
      templateLockCount: 0,
      allowInstantComplete: false,
      logs: const <TaskLogEntry>[],
      taskKind: TaskKind.project,
      description: 'Refresh visuals and copy.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectMilestonesProvider.overrideWithProvider((projectId) {
            return StreamProvider<List<Task>>((ref) {
              return Stream.value(const <Task>[]);
            });
          }),
          projectsExpandedTaskIdProvider.overrideWith((ref) => project.id),
          taskEditActionsNotifierProvider.overrideWith(() => _FakeTaskEditActions()),
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ProjectCard(project: project)),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Landing Page Revamp'), findsOneWidget);
    expect(find.textContaining('Refresh visuals'), findsOneWidget);
  });
}

