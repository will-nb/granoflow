import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../data/models/task.dart';
import '../../../data/models/focus_session.dart';

/// 日视图详情组件，显示当日统计和时间轴表格（类似 Outlook）
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

        return Column(
          children: [
            // 统计摘要
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildStatsSummary(context, l10n, detail),
            ),
            const Divider(height: 1),
            // 时间轴表格
            Expanded(
              child: _buildTimeGrid(context, detail, selectedDate),
            ),
          ],
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

  /// 构建时间轴表格（类似 Outlook）
  /// 每半小时一栏，显示任务和会话
  Widget _buildTimeGrid(
    BuildContext context,
    detail,
    DateTime selectedDate,
  ) {
    // 生成 24 小时的时间段（每半小时一栏，共 48 栏）
    final timeSlots = <TimeSlot>[];
    for (int hour = 0; hour < 24; hour++) {
      timeSlots.add(TimeSlot(
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, 0),
        end: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, 30),
      ));
      timeSlots.add(TimeSlot(
        start: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour, 30),
        end: hour < 23
            ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour + 1, 0)
            : DateTime(selectedDate.year, selectedDate.month, selectedDate.day + 1, 0, 0),
      ));
    }

    // 将任务和会话分配到对应的时间段
    final tasksBySlot = <int, List<Task>>{};
    final sessionsBySlot = <int, List<FocusSession>>{};

    for (final task in detail.completedTasks) {
      if (task.endedAt == null) continue;
      final slotIndex = _findTimeSlotIndex(timeSlots, task.endedAt!);
      if (slotIndex != null) {
        tasksBySlot.putIfAbsent(slotIndex, () => []).add(task);
      }
    }

    for (final session in detail.sessions) {
      if (session.endedAt == null) continue;
      final slotIndex = _findTimeSlotIndex(timeSlots, session.endedAt!);
      if (slotIndex != null) {
        sessionsBySlot.putIfAbsent(slotIndex, () => []).add(session);
      }
    }

    return ListView.builder(
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final slot = timeSlots[index];
        final tasks = tasksBySlot[index] ?? [];
        final sessions = sessionsBySlot[index] ?? [];
        final hasData = tasks.isNotEmpty || sessions.isNotEmpty;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            color: hasData
                ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 时间标签（左侧）
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  _formatTime(slot.start),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                ),
              ),
              // 内容区域（右侧）
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 任务列表
                      ...tasks.take(2).map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (tasks.length > 2)
                        Text(
                          '+${tasks.length - 2} more',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                        ),
                      // 会话列表
                      ...sessions.take(2).map((session) => Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  CalendarReviewUtils.formatFocusMinutes(session.actualMinutes),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                ),
                                if (session.taskId != null) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Task session',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )),
                      if (sessions.length > 2)
                        Text(
                          '+${sessions.length - 2} more sessions',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 10,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 查找时间点所在的时间段索引
  int? _findTimeSlotIndex(List<TimeSlot> slots, DateTime time) {
    for (int i = 0; i < slots.length; i++) {
      final slot = slots[i];
      if ((time.isAfter(slot.start.subtract(const Duration(milliseconds: 1))) &&
              time.isBefore(slot.end)) ||
          time.isAtSameMomentAs(slot.start)) {
        return i;
      }
    }
    return null;
  }

  /// 格式化时间显示
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// 时间段数据类
class TimeSlot {
  const TimeSlot({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
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
