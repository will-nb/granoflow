import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/widgets/project_progress_bar.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('ProjectProgressBar', () {
    testWidgets('shows empty message when total is 0', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ProjectProgressBar(
            progress: 0.0,
            completed: 0,
            total: 0,
            overdue: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProjectProgressBar)),
      );
      expect(find.text(l10n.projectProgressEmpty), findsOneWidget);
    });

    testWidgets('shows progress label when total > 0', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ProjectProgressBar(
            progress: 0.5,
            completed: 2,
            total: 4,
            overdue: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProjectProgressBar)),
      );
      expect(
        find.text(l10n.projectProgressLabel(50, 2, 4)),
        findsOneWidget,
      );
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const ProjectProgressBar(
            progress: 0.5,
            completed: 2,
            total: 4,
            overdue: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}

