import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:granoflow/core/providers/app_config_providers.dart';
import 'package:granoflow/core/providers/home_statistics_providers.dart';
import 'package:granoflow/data/models/home_statistics.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/home/widgets/home_empty_state_card.dart';
import 'package:granoflow/presentation/home/widgets/home_statistics_widget.dart';

void main() {
  const zeroStats = HomeStatistics(completedCount: 0, focusMinutes: 0);
  const emptyStatistics = AllStatistics(
    today: zeroStats,
    thisWeek: zeroStats,
    thisMonth: zeroStats,
    total: zeroStats,
  );

  const nonZeroStats = HomeStatistics(completedCount: 3, focusMinutes: 30);
  const nonEmptyStatistics = AllStatistics(
    today: nonZeroStats,
    thisWeek: nonZeroStats,
    thisMonth: nonZeroStats,
    total: nonZeroStats,
  );

  GoRouter _buildRouter(Widget child) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MediaQuery(
            data: const MediaQueryData(size: Size(900, 600), devicePixelRatio: 1),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
        GoRoute(
          path: '/inbox',
          builder: (context, state) => const Scaffold(body: Text('Inbox Page')),
        ),
      ],
    );
  }

  Future<void> pumpStatisticsWidget(
    WidgetTester tester, {
    required AllStatistics statistics,
  }) async {
    final router = _buildRouter(const HomeStatisticsWidget());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seedInitializerProvider.overrideWith((ref) async {}),
          allStatisticsProvider.overrideWith((ref) async => statistics),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows embedded empty state card when statistics are empty', (tester) async {
    await pumpStatisticsWidget(tester, statistics: emptyStatistics);

    expect(find.byType(HomeEmptyStateCard), findsOneWidget);
    expect(find.text('Create first task'), findsOneWidget);
  });

  testWidgets('tapping primary CTA navigates to inbox route', (tester) async {
    await pumpStatisticsWidget(tester, statistics: emptyStatistics);

    await tester.tap(find.text('Create first task'));
    await tester.pumpAndSettle();

    expect(find.text('Inbox Page'), findsOneWidget);
  });

  testWidgets('renders statistics table when data is available', (tester) async {
    await pumpStatisticsWidget(tester, statistics: nonEmptyStatistics);

    expect(find.byType(HomeEmptyStateCard), findsNothing);
    expect(find.textContaining('Statistics'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
