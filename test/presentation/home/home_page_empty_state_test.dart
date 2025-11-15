import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:granoflow/core/providers/app_config_providers.dart';
import 'package:granoflow/core/providers/home_statistics_providers.dart';
import 'package:granoflow/data/models/home_statistics.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';
import 'package:granoflow/presentation/home/home_page.dart';
import 'package:granoflow/presentation/home/widgets/home_empty_state_card.dart';
import 'package:granoflow/presentation/home/widgets/home_statistics_widget.dart';
import 'package:granoflow/presentation/home/widgets/task_search_bar.dart';

void main() {
  const zeroStats = HomeStatistics(completedCount: 0, focusMinutes: 0);
  const emptyStatistics = AllStatistics(
    today: zeroStats,
    thisWeek: zeroStats,
    thisMonth: zeroStats,
    total: zeroStats,
  );

  const nonZeroStats = HomeStatistics(completedCount: 3, focusMinutes: 45);
  const nonEmptyStatistics = AllStatistics(
    today: nonZeroStats,
    thisWeek: nonZeroStats,
    thisMonth: nonZeroStats,
    total: nonZeroStats,
  );

  GoRouter _buildRouter(Size size, Widget child) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => MediaQuery(
            data: MediaQueryData(size: size, devicePixelRatio: 1, padding: EdgeInsets.zero),
            child: child,
          ),
        ),
        GoRoute(
          path: '/inbox',
          builder: (context, state) => const Scaffold(body: Text('Inbox Placeholder')),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const Scaffold(body: Text('Search Placeholder')),
        ),
      ],
    );
  }

  Future<void> pumpHomePage(
    WidgetTester tester, {
    required Size size,
    required AllStatistics statistics,
  }) async {
    final router = _buildRouter(size, const HomePage());
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

  testWidgets('shows illustration card in wide empty layout', (tester) async {
    await pumpHomePage(tester, size: const Size(1024, 768), statistics: emptyStatistics);

    expect(find.byType(HomeEmptyStateCard), findsOneWidget);
    expect(find.text('Create first task'), findsOneWidget);
    expect(find.byType(TaskSearchBar), findsOneWidget);
  });

  testWidgets('renders scrollable empty layout on narrow screens', (tester) async {
    await pumpHomePage(tester, size: const Size(390, 844), statistics: emptyStatistics);

    expect(find.byType(HomeEmptyStateCard), findsOneWidget);
    expect(find.text('Create first task'), findsOneWidget);
  });

  testWidgets('hides empty illustration when statistics exist', (tester) async {
    await pumpHomePage(tester, size: const Size(1024, 768), statistics: nonEmptyStatistics);

    expect(find.byType(HomeEmptyStateCard), findsNothing);
    expect(find.byType(HomeStatisticsWidget), findsOneWidget);
  });
}
