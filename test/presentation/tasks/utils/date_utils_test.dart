import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:granoflow/data/models/task.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/tasks/utils/date_utils.dart';
import 'package:intl/intl.dart';

void main() {
  group('defaultDueDate', () {
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);

    test('returns yesterday for overdue', () {
      final result = defaultDueDate(TaskSection.overdue);
      expect(baseDate.difference(result).inDays, 1);
    });

    test('returns today for today', () {
      final result = defaultDueDate(TaskSection.today);
      expect(result.year, baseDate.year);
      expect(result.month, baseDate.month);
      expect(result.day, baseDate.day);
    });

    test('returns tomorrow for tomorrow', () {
      final result = defaultDueDate(TaskSection.tomorrow);
      expect(result.difference(baseDate).inDays, 1);
    });

    test('returns 2 days later for this week', () {
      final result = defaultDueDate(TaskSection.thisWeek);
      expect(result.difference(baseDate).inDays, 2);
    });

    test('returns 7 days later for this month', () {
      final result = defaultDueDate(TaskSection.thisMonth);
      expect(result.difference(baseDate).inDays, 7);
    });

    test('returns 30 days later for later', () {
      final result = defaultDueDate(TaskSection.later);
      expect(result.difference(baseDate).inDays, 30);
    });

    test('returns today for completed', () {
      final result = defaultDueDate(TaskSection.completed);
      expect(result.year, baseDate.year);
      expect(result.month, baseDate.month);
      expect(result.day, baseDate.day);
    });

    test('returns today for archived', () {
      final result = defaultDueDate(TaskSection.archived);
      expect(result.year, baseDate.year);
      expect(result.month, baseDate.month);
      expect(result.day, baseDate.day);
    });

    test('returns today for trash', () {
      final result = defaultDueDate(TaskSection.trash);
      expect(result.year, baseDate.year);
      expect(result.month, baseDate.month);
      expect(result.day, baseDate.day);
    });
  });

  group('formatDeadline', () {
    testWidgets('returns null for null date', (tester) async {
      await tester.pumpWidget(_TestApp(
        builder: (context) {
          final result = formatDeadline(context, null);
          expect(result, isNull);
          return const SizedBox();
        },
      ));
    });

    testWidgets('formats date correctly', (tester) async {
      final date = DateTime(2025, 10, 30);
      await tester.pumpWidget(_TestApp(
        builder: (context) {
          final result = formatDeadline(context, date);
          expect(result, isNotNull);
          final locale = AppLocalizations.of(context).localeName;
          // formatDeadline 使用 DateFormat.yMMMd(locale)，我们仅断言字符串一致。
          final formatted = formatDeadline(context, date);
          expect(formatted, isNotNull);
          expect(formatted, DateFormat.yMMMd(locale).format(date));
          return const SizedBox();
        },
      ));
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.builder});

  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: builder),
    );
  }
}

