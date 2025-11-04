import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/core/providers/service_providers.dart';
import 'package:granoflow/core/services/task_service.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/projects/project_creation_sheet.dart';

class _FakeTaskService extends Fake implements TaskService {}

void main() {
  testWidgets('ProjectCreationSheet renders title field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskServiceProvider.overrideWith((ref) => _FakeTaskService()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProjectCreationSheet()),
        ),
      ),
    );

    await tester.pump();

    final context = tester.element(find.byType(ProjectCreationSheet));
    final l10n = AppLocalizations.of(context);
    expect(find.text(l10n.projectSheetTitle), findsOneWidget);
  });
}

