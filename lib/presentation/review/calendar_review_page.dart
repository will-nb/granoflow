import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:share_plus/share_plus.dart'; // TODO: 图片分享
import 'package:table_calendar/table_calendar.dart';
import '../../../core/providers/calendar_review_providers.dart';
// import '../../../core/providers/service_providers.dart'; // TODO: 图片分享
import '../../../core/theme/ocean_breeze_color_schemes.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/main_drawer.dart';
import '../widgets/page_app_bar.dart';
// import 'utils/markdown_export_generator.dart'; // TODO: 图片分享
// import 'widgets/calendar_filter_sheet.dart'; // 筛选功能（当前版本禁用）
import 'widgets/calendar_heatmap_cell.dart';
import 'widgets/day_detail_view.dart';
// import 'widgets/export_date_range_dialog.dart'; // TODO: 图片分享
import 'widgets/month_detail_view.dart';
import 'widgets/view_toggle_bar.dart';
import 'widgets/week_detail_view.dart';

/// 日历回顾主页面
class CalendarReviewPage extends ConsumerStatefulWidget {
  const CalendarReviewPage({super.key});

  @override
  ConsumerState<CalendarReviewPage> createState() => _CalendarReviewPageState();
}

class _CalendarReviewPageState extends ConsumerState<CalendarReviewPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final state = ref.read(calendarReviewNotifierProvider);
    final notifier = ref.read(calendarReviewNotifierProvider.notifier);
    
    // 根据当前视图模式加载数据
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end;

    switch (state.viewMode) {
      case CalendarViewMode.day:
        start = today;
        end = today;
        break;
      case CalendarViewMode.week:
        start = CalendarReviewUtils.getWeekStart(now);
        end = CalendarReviewUtils.getWeekEnd(now);
        break;
      case CalendarViewMode.month:
        start = CalendarReviewUtils.getMonthStart(now);
        end = CalendarReviewUtils.getMonthEnd(now);
        break;
    }

    // 如果还没有选中日期，默认选中今天
    if (state.selectedDate == null) {
      notifier.selectDate(today);
      _selectedDay = today;
      _focusedDay = today;
    }

    notifier.loadDailyData(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(calendarReviewNotifierProvider);
    final notifier = ref.read(calendarReviewNotifierProvider.notifier);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // 同步选中日期
    if (state.selectedDate != null && state.selectedDate != _selectedDay) {
      _selectedDay = state.selectedDate!;
      _focusedDay = _selectedDay;
    }

    // 同步视图模式
    // 日视图不显示日历，只显示时间轴表格
    final calendarFormat = switch (state.viewMode) {
      CalendarViewMode.day => CalendarFormat.month, // 日视图仍使用月视图显示（用于选择日期）
      CalendarViewMode.week => CalendarFormat.week,
      CalendarViewMode.month => CalendarFormat.month,
    };
    if (calendarFormat != _calendarFormat) {
      _calendarFormat = calendarFormat;
    }

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.calendarReviewPageTitle,
        actions: [
          // 筛选按钮（当前版本禁用）
          // IconButton(
          //   icon: const Icon(Icons.filter_list),
          //   onPressed: () => _showFilterSheet(context),
          //   tooltip: l10n.calendarReviewFilter,
          // ),
          // TODO: 图片分享
          // 导出按钮（当前版本禁用）
          // IconButton(
          //   icon: const Icon(Icons.share),
          //   onPressed: () => _showExportDialog(context),
          //   tooltip: l10n.calendarReviewExport,
          // ),
        ],
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          // 视图切换工具栏
          const ViewToggleBar(),
          // 根据视图模式和屏幕方向选择布局
          Expanded(
            child: _buildMainContent(context, state, notifier, isLandscape),
          ),
        ],
      ),
    );
  }

  /// 构建主要内容区域
  /// 根据屏幕方向和视图模式选择布局方式
  Widget _buildMainContent(
    BuildContext context,
    dynamic state,
    dynamic notifier,
    bool isLandscape,
  ) {
    // 日视图和周视图：直接全屏显示时间轴表格
    if (state.viewMode == CalendarViewMode.day || 
        state.viewMode == CalendarViewMode.week) {
      return _buildDetailView(state.viewMode);
    }

    // 月视图：根据屏幕方向选择布局（TableCalendar + 详情）
    if (isLandscape) {
      // 横屏：左右分栏
      return _buildLandscapeLayout(context, state, notifier);
    } else {
      // 竖屏：上下分栏
      return _buildPortraitLayout(context, state, notifier);
    }
  }

  /// 横屏布局：左右分栏（日历在左，详情在右）
  Widget _buildLandscapeLayout(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Row(
      children: [
        // 左侧：日历（占 55% 宽度，带右侧内边距）
        Expanded(
          flex: 55,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              eventLoader: (day) {
                final date = DateTime(day.year, day.month, day.day);
                final data = state.dailyData[date];
                // 只有当有已完成任务时才返回非空列表（显示圆点）
                if (data != null && (data.completedTaskCount ?? 0) > 0) {
                  return [data];
                }
                return [];
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                
                notifier.selectDate(selectedDay);
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadDataForVisibleRange(focusedDay, state.viewMode);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, events) {
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  final data = state.dailyData[dateOnly];
                  final isSelected = isSameDay(_selectedDay, date);
                  final isToday = isSameDay(DateTime.now(), date);
                  
                  return CalendarHeatmapCell(
                    date: dateOnly,
                    data: data,
                    isSelected: isSelected,
                    isToday: isToday,
                    showFocusMinutes: state.viewMode == CalendarViewMode.day,
                  );
                },
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: (Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ) ?? const TextStyle()),
                formatButtonVisible: false,
                leftChevronIcon: const Icon(Icons.chevron_left),
                rightChevronIcon: const Icon(Icons.chevron_right),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ) ?? const TextStyle(),
                weekendStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.error,
                    ) ?? const TextStyle(),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                markerDecoration: BoxDecoration(
                  color: OceanBreezeColorSchemes.lakeCyan,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                selectedDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        // 右侧：详情区域（占 45% 宽度，卡片式设计）
        Expanded(
          flex: 45,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                // Light 模式使用天际白（tertiaryContainer），Dark 模式使用 surfaceContainerHighest
                color: Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.tertiaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: _buildDetailView(state.viewMode),
            ),
          ),
        ),
      ],
    );
  }

  /// 竖屏布局：上下分栏（日历在上，详情在下）
  Widget _buildPortraitLayout(
    BuildContext context,
    dynamic state,
    dynamic notifier,
  ) {
    return Column(
      children: [
        // 日历
        Expanded(
          child: TableCalendar(
            firstDay: DateTime(2020, 1, 1),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            eventLoader: (day) {
              final date = DateTime(day.year, day.month, day.day);
              final data = state.dailyData[date];
              // 只有当有已完成任务时才返回非空列表（显示圆点）
              if (data != null && (data.completedTaskCount ?? 0) > 0) {
                return [data];
              }
              return [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              
              notifier.selectDate(selectedDay);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
              _loadDataForVisibleRange(focusedDay, state.viewMode);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, events) {
                final dateOnly = DateTime(date.year, date.month, date.day);
                final data = state.dailyData[dateOnly];
                final isSelected = isSameDay(_selectedDay, date);
                final isToday = isSameDay(DateTime.now(), date);
                
                return CalendarHeatmapCell(
                  date: dateOnly,
                  data: data,
                  isSelected: isSelected,
                  isToday: isToday,
                  showFocusMinutes: state.viewMode == CalendarViewMode.day,
                );
              },
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: (Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ) ?? const TextStyle()),
              formatButtonVisible: false,
              leftChevronIcon: const Icon(Icons.chevron_left),
              rightChevronIcon: const Icon(Icons.chevron_right),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ) ?? const TextStyle(),
              weekendStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.error,
                  ) ?? const TextStyle(),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              markerDecoration: BoxDecoration(
                color: OceanBreezeColorSchemes.lakeCyan,
                shape: BoxShape.circle,
              ),
                todayDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                selectedDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          // 详情区域
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: _buildDetailView(state.viewMode),
          ),
        ],
    );
  }

  Widget _buildDetailView(CalendarViewMode viewMode) {
    switch (viewMode) {
      case CalendarViewMode.day:
        return const DayDetailView();
      case CalendarViewMode.week:
        return const WeekDetailView();
      case CalendarViewMode.month:
        return const MonthDetailView();
    }
  }

  void _loadDataForVisibleRange(DateTime focusedDay, CalendarViewMode viewMode) {
    final notifier = ref.read(calendarReviewNotifierProvider.notifier);
    DateTime start;
    DateTime end;

    switch (viewMode) {
      case CalendarViewMode.day:
        start = DateTime(focusedDay.year, focusedDay.month, focusedDay.day);
        end = start;
        break;
      case CalendarViewMode.week:
        start = CalendarReviewUtils.getWeekStart(focusedDay);
        end = CalendarReviewUtils.getWeekEnd(focusedDay);
        break;
      case CalendarViewMode.month:
        start = CalendarReviewUtils.getMonthStart(focusedDay);
        end = CalendarReviewUtils.getMonthEnd(focusedDay);
        // 预加载前后各一个月
        final prevMonth = DateTime(focusedDay.year, focusedDay.month - 1, 1);
        final nextMonth = DateTime(focusedDay.year, focusedDay.month + 1, 1);
        start = CalendarReviewUtils.getMonthStart(prevMonth);
        end = CalendarReviewUtils.getMonthEnd(nextMonth);
        break;
    }

    notifier.loadDailyData(start: start, end: end);
  }

  // 筛选功能（当前版本禁用）
  // void _showFilterSheet(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => Container(
  //       decoration: BoxDecoration(
  //         color: Theme.of(context).colorScheme.surface,
  //         borderRadius: const BorderRadius.only(
  //           topLeft: Radius.circular(20),
  //           topRight: Radius.circular(20),
  //         ),
  //       ),
  //       child: const CalendarFilterSheet(),
  //     ),
  //   );
  // }

  // TODO: 图片分享
  // 导出功能（当前版本禁用）
  // Future<void> _showExportDialog(BuildContext context) async {
  //   final l10n = AppLocalizations.of(context);
  //   final result = await showDialog<Map<String, DateTime?>>(
  //     context: context,
  //     builder: (context) => const ExportDateRangeDialog(),
  //   );
  //
  //   if (result == null || !context.mounted) return;
  //
  //   final start = result['start'];
  //   final end = result['end'];
  //   if (start == null || end == null) return;
  //
  //   try {
  //     final state = ref.read(calendarReviewNotifierProvider);
  //     final service = await ref.read(calendarReviewServiceProvider.future);
  //     final generator = MarkdownExportGenerator(
  //       service: service,
  //       l10n: l10n,
  //     );
  //
  //     final viewModeName = switch (state.viewMode) {
  //       CalendarViewMode.day => 'Day',
  //       CalendarViewMode.week => 'Week',
  //       CalendarViewMode.month => 'Month',
  //     };
  //     
  //     final markdown = await generator.generateMarkdown(
  //       start: start,
  //       end: end,
  //       filter: state.filter,
  //       viewMode: viewModeName,
  //     );
  //
  //     await Share.share(markdown);
  //   } catch (e) {
  //     if (!context.mounted) return;
  //     final errorMessage = l10n.calendarReviewExportFailed(e.toString());
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(errorMessage),
  //       ),
  //     );
  //   }
  // }
}
