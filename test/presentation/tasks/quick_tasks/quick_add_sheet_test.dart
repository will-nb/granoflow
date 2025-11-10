import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/core/theme/app_theme.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/quick_tasks/quick_add_sheet.dart';
import 'package:granoflow/core/providers/repository_providers.dart';
import '../../test_support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('QuickAddSheet returns result when submitting', (tester) async {
    QuickAddResult? result;
    final taskRepository = StubTaskRepository();
    final tagRepository = StubTagRepository();
    final focusRepository = StubFocusSessionRepository();
    final preferenceRepository = StubPreferenceRepository();
    final templateRepository = StubTaskTemplateRepository();
    final seedRepository = StubSeedRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepository),
          tagRepositoryProvider.overrideWithValue(tagRepository),
          focusSessionRepositoryProvider.overrideWithValue(focusRepository),
          preferenceRepositoryProvider.overrideWithValue(preferenceRepository),
          taskTemplateRepositoryProvider.overrideWithValue(templateRepository),
          seedRepositoryProvider.overrideWithValue(seedRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showModalBottomSheet<QuickAddResult>(
                      context: context,
                      isScrollControlled: true,
                      builder: (sheetContext) => const QuickAddSheet(
                        section: TaskSection.today,
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Plan refactor');

    final sheetContext = tester.element(find.byType(QuickAddSheet));
    final l10n = AppLocalizations.of(sheetContext);

    await tester.tap(find.text(l10n.commonAdd));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.title, 'Plan refactor');
    expect(result!.dueDate, isA<DateTime>());
  });
}
