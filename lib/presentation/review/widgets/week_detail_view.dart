import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 周视图详情组件，显示本周统计摘要
class WeekDetailView extends ConsumerWidget {
  const WeekDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calendarReviewNotifierProvider);
    final selectedDate = state.selectedDate ?? DateTime.now();

    final weekDataAsync = ref.watch(weekDataProvider(selectedDate));

    return weekDataAsync.when(
      data: (weekData) {
        if (weekData.totalFocusMinutes == 0 &&
            weekData.completedTaskCount == 0) {
          return Center(
            child: Text(
              l10n.calendarReviewEmptyState,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                label: l10n.calendarReviewStatsTotalFocus,
                value: CalendarReviewUtils.formatFocusMinutes(
                  weekData.totalFocusMinutes,
                ),
              ),
              _StatCard(
                label: l10n.calendarReviewStatsCompletedTasks,
                value: '${weekData.completedTaskCount}',
              ),
              _StatCard(
                label: l10n.calendarReviewStatsAverageDaily,
                value: CalendarReviewUtils.formatFocusMinutes(
                  weekData.averageDailyMinutes,
                ),
              ),
              _StatCard(
                label: l10n.calendarReviewFocusSessions,
                value: '${weekData.sessionCount}',
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          '${l10n.calendarReviewLoadError}: $error',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
