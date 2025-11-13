import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/heatmap_color_service.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 月视图详情组件，显示本月统计摘要和热力图图例
class MonthDetailView extends ConsumerWidget {
  const MonthDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calendarReviewNotifierProvider);
    final selectedDate = state.selectedDate ?? DateTime.now();

    final monthDataAsync = ref.watch(monthDataProvider(selectedDate));
    final heatmapServiceAsync = ref.watch(heatmapColorServiceProvider);

    return monthDataAsync.when(
      data: (monthData) {
        // 获取当日数据
        final selectedDateNormalized = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        final todayData = state.dailyData[selectedDateNormalized];
        final todayFocusMinutes = todayData?.focusMinutes ?? 0;
        final todayCompletedTasks = todayData?.completedTaskCount ?? 0;

        if (monthData.totalFocusMinutes == 0 &&
            monthData.completedTaskCount == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_view_month_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
              l10n.calendarReviewEmptyState,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.calendarReviewEmptyStateDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计摘要
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  // 第一行：当日统计
                  _StatCard(
                    label: l10n.calendarReviewStatsTodayFocus,
                    value: CalendarReviewUtils.formatFocusMinutes(todayFocusMinutes),
                    onTap: () {
                      final notifier = ref.read(calendarReviewNotifierProvider.notifier);
                      notifier.setViewMode(CalendarViewMode.day);
                      notifier.selectDate(selectedDateNormalized);
                      notifier.loadDailyData(
                        start: selectedDateNormalized,
                        end: selectedDateNormalized,
                      );
                    },
                  ),
                  _StatCard(
                    label: l10n.calendarReviewStatsTodayTasks,
                    value: '$todayCompletedTasks',
                    onTap: () {
                      final notifier = ref.read(calendarReviewNotifierProvider.notifier);
                      notifier.setViewMode(CalendarViewMode.day);
                      notifier.selectDate(selectedDateNormalized);
                      notifier.loadDailyData(
                        start: selectedDateNormalized,
                        end: selectedDateNormalized,
                      );
                    },
                  ),
                  // 第二行：月度总计
                  _StatCard(
                    label: l10n.calendarReviewStatsTotalFocus,
                    value: CalendarReviewUtils.formatFocusMinutes(
                      monthData.totalFocusMinutes,
                    ),
                  ),
                  _StatCard(
                    label: l10n.calendarReviewStatsCompletedTasks,
                    value: '${monthData.completedTaskCount}',
                  ),
                  // 第三行：月度平均和最活跃日期
                  _StatCard(
                    label: l10n.calendarReviewStatsAverageDaily,
                    value: CalendarReviewUtils.formatFocusMinutes(
                      monthData.averageDailyMinutes,
                    ),
                  ),
                  _StatCard(
                    label: l10n.calendarReviewStatsMostActiveDate,
                    value: monthData.mostActiveDate != null
                        ? DateFormat('MM/dd').format(monthData.mostActiveDate!)
                        : '-',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // 热力图图例
              if (heatmapServiceAsync.value != null)
                _buildHeatmapLegend(context, l10n, heatmapServiceAsync.value!),
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

  Widget _buildHeatmapLegend(
    BuildContext context,
    AppLocalizations l10n,
    HeatmapColorService service,
  ) {
    final brightness = Theme.of(context).brightness;
    // 使用默认阈值（实际应该从配置读取，但这里简化处理）
    const low = 30;
    const mediumLow = 60;
    const medium = 120;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.calendarReviewHeatmapLegend,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        _LegendItem(
          color: service.getHeatmapColor(0, brightness),
          label: l10n.calendarReviewHeatmapLegendNone,
        ),
        _LegendItem(
          color: service.getHeatmapColor(low ~/ 2, brightness),
          label: l10n.calendarReviewHeatmapLegendLow(low),
        ),
        _LegendItem(
          color: service.getHeatmapColor((low + mediumLow) ~/ 2, brightness),
          label: l10n.calendarReviewHeatmapLegendMedium(low, mediumLow),
        ),
        _LegendItem(
          color: service.getHeatmapColor((mediumLow + medium) ~/ 2, brightness),
          label: l10n.calendarReviewHeatmapLegendMedium(mediumLow, medium),
        ),
        _LegendItem(
          color: service.getHeatmapColor(medium + 10, brightness),
          label: l10n.calendarReviewHeatmapLegendHigh(medium),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 如果有点击回调，使用主题链接颜色；否则使用默认颜色
    final textColor = onTap != null ? theme.colorScheme.primary : null;
    
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    // 如果有点击回调，包装为可点击的链接样式
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
