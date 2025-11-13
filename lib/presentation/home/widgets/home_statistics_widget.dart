import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/home_statistics_providers.dart';
import '../../../core/utils/home_statistics_utils.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 首页统计表组件
class HomeStatisticsWidget extends ConsumerWidget {
  const HomeStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final allStatisticsAsync = ref.watch(allStatisticsProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      color: theme.cardColor.withValues(alpha: 0.95),
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: allStatisticsAsync.when(
          data: (allStatistics) {
            if (allStatistics.today.completedCount == 0 &&
                allStatistics.today.focusMinutes == 0 &&
                allStatistics.thisWeek.completedCount == 0 &&
                allStatistics.thisWeek.focusMinutes == 0 &&
                allStatistics.thisMonth.completedCount == 0 &&
                allStatistics.thisMonth.focusMinutes == 0 &&
                allStatistics.total.completedCount == 0 &&
                allStatistics.total.focusMinutes == 0) {
              // 空状态
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.homeStatisticsEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标题
                Text(
                  l10n.homeStatisticsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                // 统计表格
                _buildStatisticsTable(context, theme, l10n, allStatistics),
              ],
            );
          },
          loading: () => _buildSkeleton(theme),
          error: (error, stack) => Center(
            child: Text(
              'Error: $error',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTable(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    dynamic allStatistics,
  ) {
    final rows = <Widget>[
      _buildStatRow(
        context,
        theme,
        l10n.homeStatisticsToday,
        allStatistics.today.completedCount,
        allStatistics.today.focusMinutes,
        false,
      ),
      _buildStatRow(
        context,
        theme,
        l10n.homeStatisticsThisWeek,
        allStatistics.thisWeek.completedCount,
        allStatistics.thisWeek.focusMinutes,
        false,
      ),
      _buildStatRow(
        context,
        theme,
        l10n.homeStatisticsThisMonth,
        allStatistics.thisMonth.completedCount,
        allStatistics.thisMonth.focusMinutes,
        false,
      ),
      _buildStatRow(
        context,
        theme,
        l10n.homeStatisticsTotal,
        allStatistics.total.completedCount,
        allStatistics.total.focusMinutes,
        false,
      ),
    ];

    // 当月最佳完成日
    if (allStatistics.thisMonthTopCompletedDate != null) {
      rows.add(
        _buildTopDateRow(
          context,
          theme,
          l10n.homeStatisticsThisMonthTopCompletedDate,
          allStatistics.thisMonthTopCompletedDate!.date,
          allStatistics.thisMonthTopCompletedDate!.completedCount,
          null,
          isThisMonth: true,
        ),
      );
    }

    // 当月最佳专注日
    if (allStatistics.thisMonthTopFocusDate != null) {
      rows.add(
        _buildTopDateRow(
          context,
          theme,
          l10n.homeStatisticsThisMonthTopFocusDate,
          allStatistics.thisMonthTopFocusDate!.date,
          null,
          allStatistics.thisMonthTopFocusDate!.focusMinutes,
          isThisMonth: true,
        ),
      );
    }

    // 历史最佳完成日
    if (allStatistics.totalTopCompletedDate != null) {
      rows.add(
        _buildTopDateRow(
          context,
          theme,
          l10n.homeStatisticsTotalTopCompletedDate,
          allStatistics.totalTopCompletedDate!.date,
          allStatistics.totalTopCompletedDate!.completedCount,
          null,
          isThisMonth: false,
        ),
      );
    }

    // 历史最佳专注日
    if (allStatistics.totalTopFocusDate != null) {
      rows.add(
        _buildTopDateRow(
          context,
          theme,
          l10n.homeStatisticsTotalTopFocusDate,
          allStatistics.totalTopFocusDate!.date,
          null,
          allStatistics.totalTopFocusDate!.focusMinutes,
          isThisMonth: false,
        ),
      );
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final isLast = index == rows.length - 1;
        return Column(
          children: [
            row,
            if (!isLast)
              Divider(
                height: 1,
                thickness: 0.5,
                color: theme.colorScheme.outline.withValues(alpha: 0.08),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    ThemeData theme,
    String label,
    int completedCount,
    int focusMinutes,
    bool isHighlight,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              letterSpacing: 0.1,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completedCount',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                HomeStatisticsUtils.formatFocusMinutes(focusMinutes),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopDateRow(
    BuildContext context,
    ThemeData theme,
    String label,
    DateTime date,
    int? completedCount,
    int? focusMinutes, {
    required bool isThisMonth,
  }) {
    final colorScheme = theme.colorScheme;
    final formattedDate = HomeStatisticsUtils.formatTopDate(context, date, isThisMonth: isThisMonth);
    final value = completedCount != null
        ? '$completedCount'
        : HomeStatisticsUtils.formatFocusMinutes(focusMinutes!);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              letterSpacing: 0.1,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题骨架
        Container(
          width: 100,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        // 6行数据骨架
        ...List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

