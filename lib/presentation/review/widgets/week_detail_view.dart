import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_week_view/flutter_week_view.dart';
import '../../../core/providers/calendar_review_providers.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../data/models/task.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../utils/week_view_event_converter.dart';
import '../../widgets/utils/task_bottom_sheet_helper.dart';

/// 周视图详情组件，显示本周统计摘要
class WeekDetailView extends ConsumerWidget {
  const WeekDetailView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calendarReviewNotifierProvider);
    final selectedDate = state.selectedDate ?? DateTime.now();

    final weekDataAsync = ref.watch(weekDataProvider(selectedDate));
    final weekDetailAsync = ref.watch(weekDetailProvider(selectedDate));

    return weekDataAsync.when(
      data: (weekData) {
        return weekDetailAsync.when(
          data: (weekDetail) {
            // 构建一周的日期列表（周日到周六）
            final weekStart = CalendarReviewUtils.getWeekStart(selectedDate);
            final dates = List.generate(7, (index) {
              return DateTime(weekStart.year, weekStart.month, weekStart.day + index);
            });

            // 将所有事件合并到一个列表，同时创建事件到任务的映射
            final allEvents = <FlutterWeekViewEvent>[];
            final eventToTaskMap = <FlutterWeekViewEvent, Task>{};
            
            for (final date in dates) {
              final dayDetail = weekDetail[date];
              if (dayDetail != null) {
                // 为每个任务创建事件并建立映射
                for (final task in dayDetail.completedTasks) {
                  final event = WeekViewEventConverter.taskToEvent(task, context);
                  allEvents.add(event);
                  eventToTaskMap[event] = task;
                }
                // 为会话创建事件（会话不显示详情，所以不加入映射）
                final sessionEvents = WeekViewEventConverter.sessionsToEvents(
                  dayDetail.sessions,
                  context,
          );
                allEvents.addAll(sessionEvents);
              }
            }

            final notifier = ref.read(calendarReviewNotifierProvider.notifier);

            return Column(
              children: [
                // 统计摘要（带导航按钮）
                Container(
          padding: const EdgeInsets.all(16),
                  child: _buildStatsSummary(
                    context,
                    l10n,
                    weekData,
                    selectedDate,
                    notifier,
                  ),
                ),
                const Divider(height: 1),
                // WeekView 时间轴网格（即使没有数据也显示空白日程表）
                Expanded(
                  child: _buildWeekView(context, ref, dates, allEvents, eventToTaskMap),
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
    weekData,
    DateTime selectedDate,
    CalendarReviewNotifier notifier,
  ) {
    // 判断当前周是否包含今天
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final weekStart = CalendarReviewUtils.getWeekStart(selectedDate);
    final weekEnd = CalendarReviewUtils.getWeekEnd(selectedDate);
    final weekEndNormalized = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);
    
    // 如果周结束日期超过或等于今天，则禁用下一周按钮
    final isLastWeek = weekEndNormalized.isAfter(todayNormalized) || 
                       weekEndNormalized.isAtSameMomentAs(todayNormalized);

    // 计算上一周和下一周
    final prevWeekStart = weekStart.subtract(const Duration(days: 7));
    final nextWeekStart = weekStart.add(const Duration(days: 7));

    return Row(
      children: [
        // 上一周按钮
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            notifier.selectDate(prevWeekStart);
            // 触发数据加载
            final prevWeekEnd = CalendarReviewUtils.getWeekEnd(prevWeekStart);
            notifier.loadDailyData(
              start: prevWeekStart,
              end: prevWeekEnd,
            );
          },
          tooltip: l10n.calendarReviewPreviousWeek,
        ),
        // 统计摘要（中间）
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: l10n.calendarReviewStatsTotalFocus,
                value: CalendarReviewUtils.formatFocusMinutes(weekData.totalFocusMinutes),
              ),
              _StatItem(
                label: l10n.calendarReviewStatsCompletedTasks,
                value: '${weekData.completedTaskCount}',
              ),
              _StatItem(
                label: l10n.calendarReviewFocusSessions,
                value: '${weekData.sessionCount}',
              ),
            ],
          ),
        ),
        // 下一周按钮（如果超过今天则禁用）
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isLastWeek
              ? null
              : () {
                  // 检查下一周是否超过今天
                  final nextWeekEnd = CalendarReviewUtils.getWeekEnd(nextWeekStart);
                  final nextWeekEndNormalized = DateTime(
                    nextWeekEnd.year,
                    nextWeekEnd.month,
                    nextWeekEnd.day,
                  );
                  
                  if (nextWeekEndNormalized.isAfter(todayNormalized)) {
                    // 触发震动反馈
                    HapticFeedback.mediumImpact();
                    // 回退到包含今天的周
                    notifier.selectDate(todayNormalized);
                    final currentWeekEnd = CalendarReviewUtils.getWeekEnd(todayNormalized);
                    notifier.loadDailyData(
                      start: CalendarReviewUtils.getWeekStart(todayNormalized),
                      end: currentWeekEnd,
                    );
                  } else {
                    notifier.selectDate(nextWeekStart);
                    notifier.loadDailyData(
                      start: nextWeekStart,
                      end: nextWeekEnd,
                    );
                  }
                },
          tooltip: isLastWeek ? null : l10n.calendarReviewNextWeek,
        ),
      ],
    );
  }

  /// 构建 WeekView 时间轴网格
  Widget _buildWeekView(
    BuildContext context,
    WidgetRef ref,
    List<DateTime> dates,
    List<FlutterWeekViewEvent> events,
    Map<FlutterWeekViewEvent, Task> eventToTaskMap,
  ) {
    // 确保 dates 列表包含7个日期（一周7天）
    assert(dates.length == 7, 'WeekView should have exactly 7 dates');
    
    // 使用第一个日期作为初始时间（当天的早上7点）
    final initialTime = dates.isNotEmpty
        ? dates.first.copyWith(hour: 7, minute: 0)
        : DateTime.now().copyWith(hour: 7, minute: 0);
    
    // 计算每个 DayView 的宽度（确保7列都能显示）
    // 使用 MediaQuery 获取可用宽度，减去时间轴宽度，然后除以7
    final screenWidth = MediaQuery.of(context).size.width;
    final hourColumnWidth = 60.0; // 时间轴宽度（默认值）
    final availableWidth = screenWidth - hourColumnWidth;
    final dayViewWidth = availableWidth / 7;
    
    return WeekView(
      dates: dates,
      events: events,
      initialTime: initialTime,
      dayBarStyleBuilder: (date) {
        return DayBarStyle.fromDate(
          date: date,
          dateFormatter: (year, month, day) {
            // 只返回 mm-dd 格式，不显示年份
            return CalendarReviewUtils.formatDateShort(
              DateTime(year, month, day),
            );
          },
        );
      },
      eventWidgetBuilder: (event, height, width) {
        // 自定义事件 widget，添加点击处理
        return GestureDetector(
          onTap: () {
            // 从映射中获取对应的任务
            final task = eventToTaskMap[event];
            if (task != null) {
              // 显示任务详情弹窗
              TaskBottomSheetHelper.showTaskDetailBottomSheet(context, ref, task);
            }
          },
          child: FlutterWeekViewEventWidget(
            event: event,
            height: height,
            width: width,
          ),
        );
      },
      style: WeekViewStyle(
        dayViewWidth: dayViewWidth,
        dayViewSeparatorWidth: 1.0, // 添加分隔线
        dayViewSeparatorColor: Theme.of(context).dividerColor,
      ),
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
