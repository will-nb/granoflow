import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 日视图详情组件，显示当日统计和任务/会话列表
class DayDetailView extends ConsumerWidget {
  const DayDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calendarReviewNotifierProvider);
    final selectedDate = state.selectedDate;

    if (selectedDate == null) {
      return Center(
        child: Text(
          l10n.calendarReviewEmptyState,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final detailAsync = ref.watch(dayDetailProvider(selectedDate));

    return detailAsync.when(
      data: (detail) {
        if (detail.focusMinutes == 0 &&
            detail.completedTasks.isEmpty &&
            detail.sessions.isEmpty) {
          return Center(
            child: Text(
              l10n.calendarReviewEmptyState,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计摘要
              _buildStatsSummary(context, l10n, detail),
              const SizedBox(height: 24),
              // 完成任务列表
              if (detail.completedTasks.isNotEmpty) ...[
                Text(
                  l10n.calendarReviewTaskList,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildTaskList(context, detail.completedTasks),
                const SizedBox(height: 24),
              ],
              // 焦点会话列表
              if (detail.sessions.isNotEmpty) ...[
                Text(
                  l10n.calendarReviewFocusSessions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildSessionList(context, detail.sessions),
              ],
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

  Widget _buildStatsSummary(
    BuildContext context,
    AppLocalizations l10n,
    detail,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          label: l10n.calendarReviewFocusMinutes,
          value: CalendarReviewUtils.formatFocusMinutes(detail.focusMinutes),
        ),
        _StatItem(
          label: l10n.calendarReviewStatsCompletedTasks,
          value: '${detail.completedTasks.length}',
        ),
        _StatItem(
          label: l10n.calendarReviewFocusSessions,
          value: '${detail.sessions.length}',
        ),
      ],
    );
  }

  Widget _buildTaskList(BuildContext context, tasks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task.title),
          trailing: task.endedAt != null
              ? Text(
                  CalendarReviewUtils.formatFocusMinutes(
                    (task.endedAt!.difference(task.startedAt ?? task.createdAt))
                        .inMinutes,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
        );
      },
    );
  }

  Widget _buildSessionList(BuildContext context, sessions) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return ListTile(
          title: Text(
            '${session.startedAt.hour.toString().padLeft(2, '0')}:${session.startedAt.minute.toString().padLeft(2, '0')}',
          ),
          trailing: Text(
            CalendarReviewUtils.formatFocusMinutes(session.actualMinutes),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
