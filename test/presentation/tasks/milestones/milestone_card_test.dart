import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/app_providers.dart';
import 'package:granoflow/data/models/milestone.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/milestones/milestone_card.dart';

Milestone _createMilestone() {
  return Milestone(
    id: '1',

    projectId: 'project-1',
    title: 'Launch Beta',
    status: TaskStatus.pending,
    dueAt: DateTime(2025, 1, 2),
    startedAt: null,
    endedAt: null,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    sortIndex: 0,
    tags: const <String>['#urgent'],
    templateLockCount: 0,
    seedSlug: null,
    allowInstantComplete: false,
    description: 'Prepare assets and marketing copy.',
    logs: const <MilestoneLogEntry>[],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MilestoneCard renders milestone details', (tester) async {
    final milestone = _createMilestone();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          milestoneTasksProvider.overrideWithProvider((milestoneId) {
            return StreamProvider<List<Task>>((ref) {
              return Stream.value(const <Task>[]);
            });
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: MilestoneCard(milestone: milestone)),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Launch Beta'), findsOneWidget);
    expect(
      find.textContaining('Prepare assets and marketing copy.'),
      findsOneWidget,
    );
  });
}
