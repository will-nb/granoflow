import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/project_service.dart';
import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/project_card.dart';

class _FakeProjectService extends Fake implements ProjectService {}

class _FakeTaskEditActions extends TaskEditActionsNotifier {
  @override
  Future<void> build() async {}

  @override
  Future<void> archive(String taskId) async {}

  @override
  Future<void> editTitle({
    required String taskId,
    required String title,
  }) async {}
}

void main() {
  testWidgets('ProjectCard shows project title', (tester) async {
    final project = Project(
      id: '1',

      title: 'Landing Page Revamp',
      status: TaskStatus.pending,
      dueAt: DateTime(2025, 1, 15),
      startedAt: null,
      endedAt: null,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      sortIndex: 0,
      tags: const <String>['#important'],
      templateLockCount: 0,
      seedSlug: null,
      allowInstantComplete: false,
      description: 'Refresh visuals and copy.',
      logs: const <ProjectLogEntry>[],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectMilestonesDomainProvider.overrideWithProvider((projectId) {
            return StreamProvider<List<Milestone>>((ref) {
              return Stream.value(const <Milestone>[]);
            });
          }),
          milestoneTasksProvider.overrideWithProvider((milestoneId) {
            return StreamProvider<List<Task>>((ref) {
              return Stream.value(const <Task>[]);
            });
          }),
          projectsExpandedTaskIdProvider.overrideWith((ref) => project.id),
          taskEditActionsNotifierProvider.overrideWith(
            () => _FakeTaskEditActions(),
          ),
          projectServiceProvider.overrideWith((ref) => _FakeProjectService()),
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
