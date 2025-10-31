import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/inbox/widgets/inbox_quick_date_picker.dart';
import 'package:granoflow/core/theme/app_theme.dart';

void main() {
  testWidgets('InboxQuickDatePicker returns selected date', (tester) async {
    DateTime? result;
    final now = DateTime(2025, 1, 1);
    final view = tester.view;
    final originalSize = view.physicalSize;
    final originalDevicePixelRatio = view.devicePixelRatio;
    view.physicalSize = const Size(800, 1600);
    view.devicePixelRatio = 1.0;
    addTearDown(() {
      view.physicalSize = originalSize;
      view.devicePixelRatio = originalDevicePixelRatio;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<DateTime>(
                    context: context,
                    builder: (_) => InboxQuickDatePicker(
                      today: now,
                      tomorrow: now.add(const Duration(days: 1)),
                      thisWeek: now.add(const Duration(days: 3)),
                      thisMonth: DateTime(now.year, now.month, 31),
                    ),
                  );
                },
                child: const Text('open picker'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(InboxQuickDatePicker)));
    expect(find.text(l10n.datePickerToday), findsOneWidget);

    await tester.tap(find.text(l10n.datePickerToday));
    await tester.pumpAndSettle();

    expect(result, equals(now));
  });
}

