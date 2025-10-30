import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/widgets/description_block.dart';

void main() {
  group('DescriptionBlock', () {
    testWidgets('shows trimmed text and expands on tap', (tester) async {
      const description = 'This is a long description that should be trimmed.';

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: DescriptionBlock(description: description, trim: 10),
          ),
        ),
      );

      expect(find.textContaining('…'), findsOneWidget);
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text(description), findsOneWidget);
    });
  });
}

