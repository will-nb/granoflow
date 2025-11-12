import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_week_view/flutter_week_view.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/week_view_event_converter.dart';
import 'task_detail_bottom_sheet.dart';

/// 日视图详情组件，显示当日统计和时间轴表格（类似 Outlook）
class DayDetailView extends ConsumerWidget {
  const DayDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calendarReviewNotifierProvider);
    // 如果没有选中日期，默认使用今天（与周视图和月视图保持一致）
    final selectedDate = state.selectedDate ?? DateTime.now();
    final today = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    final detailAsync = ref.watch(dayDetailProvider(today));

    return detailAsync.when(
      data: (detail) {
        // 将所有事件合并到一个列表，同时创建事件到任务的映射
        final allEvents = <FlutterWeekViewEvent>[];
        final eventToTaskMap = <FlutterWeekViewEvent, Task>{};
        
        // 为每个任务创建事件并建立映射
        for (final task in detail.completedTasks) {
          final event = WeekViewEventConverter.taskToEvent(task, context);
          allEvents.add(event);
          eventToTaskMap[event] = task;
        }
        // 为会话创建事件（会话不显示详情，所以不加入映射）
        final sessionEvents = WeekViewEventConverter.sessionsToEvents(
          detail.sessions,
          context,
        );
        allEvents.addAll(sessionEvents);

        final notifier = ref.read(calendarReviewNotifierProvider.notifier);
        
        return Column(
          children: [
            // 统计摘要（带导航按钮）
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildStatsSummary(
                context,
                l10n,
                detail,
                selectedDate,
                notifier,
              ),
            ),
            const Divider(height: 1),
            // DayView 时间轴（即使没有数据也显示空白日程表）
            Expanded(
              child: _buildDayView(context, selectedDate, allEvents, eventToTaskMap),
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
    DateTime selectedDate,
    CalendarReviewNotifier notifier,
  ) {
    // 判断是否为今天
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final selectedNormalized = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday = selectedNormalized.isAtSameMomentAs(todayNormalized);

    // 计算上一天和下一天
    final prevDay = selectedNormalized.subtract(const Duration(days: 1));
    final nextDay = selectedNormalized.add(const Duration(days: 1));

    return Row(
      children: [
        // 上一天按钮
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            notifier.selectDate(prevDay);
            // 触发数据加载
            notifier.loadDailyData(
              start: prevDay,
              end: prevDay,
            );
          },
          tooltip: l10n.calendarReviewPreviousDay,
        ),
        // 统计摘要（中间）
        Expanded(
          child: Row(
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
          ),
        ),
        // 下一天按钮（如果是今天则触发动效并回退）
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            if (isToday || nextDay.isAfter(todayNormalized)) {
              // 触发震动反馈
              HapticFeedback.mediumImpact();
              // 保持在今天
              notifier.selectDate(todayNormalized);
              notifier.loadDailyData(
                start: todayNormalized,
                end: todayNormalized,
              );
            } else {
              notifier.selectDate(nextDay);
              // 触发数据加载
              notifier.loadDailyData(
                start: nextDay,
                end: nextDay,
              );
            }
          },
          tooltip: l10n.calendarReviewNextDay,
        ),
      ],
    );
  }

  /// 构建 DayView 时间轴
  Widget _buildDayView(
    BuildContext context,
    DateTime selectedDate,
    List<FlutterWeekViewEvent> events,
    Map<FlutterWeekViewEvent, Task> eventToTaskMap,
  ) {
    // 规范化日期：只保留年月日
    final date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

    return DayView(
      date: date,
      events: events,
      eventWidgetBuilder: (event, height, width) {
        // 自定义事件 widget，添加点击处理
        return GestureDetector(
          onTap: () {
            // 从映射中获取对应的任务
            final task = eventToTaskMap[event];
            if (task != null) {
              // 显示任务详情弹窗
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (sheetContext) => TaskDetailBottomSheet(task: task),
              );
            }
          },
          child: FlutterWeekViewEventWidget(
            event: event,
            height: height,
            width: width,
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
