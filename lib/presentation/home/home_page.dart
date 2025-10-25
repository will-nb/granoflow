import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../navigation/navigation_destinations.dart';
import '../timer/timer_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(seedInitializerProvider);
    
    final l10n = AppLocalizations.of(context);
    debugPrint('HomePage locale: ${Localizations.localeOf(context)}');
    debugPrint('HomePage greeting: ${l10n.homeGreeting}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final textTheme = Theme.of(context).textTheme;

          final greeting = Text(
            l10n.homeGreeting,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          );

          final subtitle = Text(
            l10n.homeTagline,
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          );

          return Center(
            child: Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_top_outlined,
                  size: isWide ? 96 : 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: isWide ? 40 : 0, height: isWide ? 0 : 32),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      greeting,
                      const SizedBox(height: 12),
                      subtitle,
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const TimerPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.actionStartTimer),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.read(navigationIndexProvider.notifier).state =
                                  NavigationDestinations.tasks.index;
                            },
                            icon: const Icon(Icons.fact_check_outlined),
                            label: Text(l10n.navPlannedTitle),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(navigationIndexProvider.notifier).state =
                                  NavigationDestinations.tasks.index;
                            },
                            icon: const Icon(Icons.inbox_outlined),
                            label: Text(l10n.navInboxTitle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
