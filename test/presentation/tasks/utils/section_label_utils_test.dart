import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/utils/section_label_utils.dart';

void main() {
  group('labelForSection', () {
    testWidgets('returns correct labels for all sections', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              
              expect(labelForSection(l10n, TaskSection.overdue), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.today), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.tomorrow), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.thisWeek), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.thisMonth), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.later), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.completed), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.archived), isNotEmpty);
              expect(labelForSection(l10n, TaskSection.trash), isNotEmpty);
              
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}

