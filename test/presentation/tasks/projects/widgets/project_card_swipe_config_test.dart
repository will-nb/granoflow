import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/data/models/project.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/widgets/project_card_swipe_config.dart';

void main() {
  Project createProject(TaskStatus status) {
    return Project(
      id: '1',

      title: 'Test Project',
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
      logs: const <ProjectLogEntry>[],
    );
  }

  Widget buildTestWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(),
    );
  }

  group('getProjectSwipeConfig', () {
    testWidgets('returns correct config for active project', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      final project = createProject(TaskStatus.pending);

      final config = getProjectSwipeConfig(project, theme, l10n);

      expect(config.leftIcon, Icons.archive_outlined);
      expect(config.rightIcon, Icons.check_circle_outline);
    });

    testWidgets('returns correct config for archived project', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      final project = createProject(TaskStatus.archived);

      final config = getProjectSwipeConfig(project, theme, l10n);

      expect(config.leftIcon, Icons.delete_outline);
      expect(config.rightIcon, Icons.restore_outlined);
    });

    testWidgets('returns correct config for trashed project', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      final project = createProject(TaskStatus.trashed);

      final config = getProjectSwipeConfig(project, theme, l10n);

      expect(config.leftIcon, Icons.delete_forever);
      expect(config.rightIcon, Icons.restore_outlined);
    });

    testWidgets('returns correct config for completed project', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      final project = createProject(TaskStatus.completedActive);

      final config = getProjectSwipeConfig(project, theme, l10n);

      expect(config.leftIcon, Icons.delete_outline);
      expect(config.rightIcon, Icons.restore_outlined);
    });
  });
}
