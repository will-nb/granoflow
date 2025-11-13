import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/widgets/project_details.dart';

void main() {
  Project createProject() {
    return Project(
      id: '1',

      title: 'Test Project',
      status: TaskStatus.pending,
      dueAt: null,
      startedAt: null,
      endedAt: null,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      sortIndex: 0,
      tags: const <String>[],
      templateLockCount: 0,
      seedSlug: null,
      allowInstantComplete: false,
      description: null,
      logs: const <ProjectLogEntry>[],
    );
  }

  Milestone createMilestone({
    String milestoneId = 'milestone-1',
    String title = 'Milestone 1',
    TaskStatus status = TaskStatus.pending,
  }) {
    return Milestone(
      id: '1',

      projectId: 'project-1',
      title: title,
      status: status,
      dueAt: null,
      startedAt: null,
      endedAt: null,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      sortIndex: 0,
      tags: const <String>[],
      templateLockCount: 0,
      seedSlug: null,
      allowInstantComplete: false,
      description: null,
      logs: const <MilestoneLogEntry>[],
    );
  }

  Widget buildTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  group('ProjectDetails', () {
    testWidgets('shows empty placeholder when no milestones', (tester) async {
      final project = createProject();

      await tester.pumpWidget(
        buildTestWidget(
          ProjectDetails(project: project, milestones: const <Milestone>[]),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProjectDetails)),
      );
      expect(find.text(l10n.projectNoMilestonesHint), findsOneWidget);
    });

    testWidgets('shows milestone cards when milestones exist', (tester) async {
      final project = createProject();
      final milestones = [
        createMilestone(title: 'Milestone 1'),
        createMilestone(title: 'Milestone 2', milestoneId: 'milestone-2'),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          ProjectDetails(project: project, milestones: milestones),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Milestone 1'), findsOneWidget);
      expect(find.text('Milestone 2'), findsOneWidget);
    });

    testWidgets('shows add milestone button', (tester) async {
      final project = createProject();

      await tester.pumpWidget(
        buildTestWidget(
          ProjectDetails(project: project, milestones: const <Milestone>[]),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProjectDetails)),
      );
      expect(find.text(l10n.milestoneAddButton), findsOneWidget);
    });
  });
}
