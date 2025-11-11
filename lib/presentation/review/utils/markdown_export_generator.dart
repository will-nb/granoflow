import '../../../core/services/calendar_review_service.dart';
import '../../../core/utils/calendar_review_utils.dart';
import '../../../data/models/calendar_review_data.dart';
import '../../../generated/l10n/app_localizations.dart';

/// 生成 Markdown 格式的导出内容
class MarkdownExportGenerator {
  MarkdownExportGenerator({
    required CalendarReviewService service,
    required AppLocalizations l10n,
  })  : _service = service,
        _l10n = l10n;

  final CalendarReviewService _service;
  final AppLocalizations _l10n;

  /// 生成 Markdown 内容
  /// 
  /// [start] 开始日期
  /// [end] 结束日期
  /// [filter] 筛选条件
  /// [viewMode] 视图模式（用于元信息）
  /// 返回 Markdown 字符串
  Future<String> generateMarkdown({
    required DateTime start,
    required DateTime end,
    CalendarFilter filter = const CalendarFilter(),
    String viewMode = 'Calendar',
  }) async {
    final dailyData = await _service.loadDailyData(
      start: start,
      end: end,
      filter: filter,
    );

    final buffer = StringBuffer();

    // 标题
    buffer.writeln('# ${_l10n.calendarReviewPageTitle}');
    buffer.writeln();

    // 元信息
    buffer.writeln('## Metadata');
    buffer.writeln();
    buffer.writeln('- **Export Time**: ${DateTime.now().toIso8601String()}');
    buffer.writeln('- **Date Range**: ${start.toIso8601String().split('T')[0]} to ${end.toIso8601String().split('T')[0]}');
    buffer.writeln('- **View Mode**: $viewMode');
    buffer.writeln();

    // 筛选条件
    if (!filter.isEmpty) {
      buffer.writeln('## ${_l10n.calendarReviewFilter}');
      buffer.writeln();
      if (filter.projectId != null) {
        buffer.writeln('- **${_l10n.calendarReviewFilterByProject}**: ${filter.projectId}');
      }
      if (filter.tags.isNotEmpty) {
        buffer.writeln('- **${_l10n.calendarReviewFilterByTags}**: ${filter.tags.join(", ")}');
      }
      buffer.writeln();
    }

    // 总体统计
    final totalFocusMinutes = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.focusMinutes);
    final totalCompletedTasks = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.completedTaskCount);
    final totalSessions = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.sessionCount);

    buffer.writeln('## Summary');
    buffer.writeln();
    buffer.writeln('- **${_l10n.calendarReviewStatsTotalFocus}**: ${CalendarReviewUtils.formatFocusMinutes(totalFocusMinutes)}');
    buffer.writeln('- **${_l10n.calendarReviewStatsCompletedTasks}**: $totalCompletedTasks');
    buffer.writeln('- **${_l10n.calendarReviewFocusSessions}**: $totalSessions');
    buffer.writeln();

    // 每日详情
    buffer.writeln('## Daily Details');
    buffer.writeln();

    final sortedDates = dailyData.keys.toList()..sort();
    for (final date in sortedDates) {
      final data = dailyData[date]!;
      final detail = await _service.loadDayDetail(date: date, filter: filter);

      buffer.writeln('### ${date.toIso8601String().split('T')[0]}');
      buffer.writeln();
      buffer.writeln('- **${_l10n.calendarReviewFocusMinutes}**: ${CalendarReviewUtils.formatFocusMinutes(data.focusMinutes)}');
      buffer.writeln('- **${_l10n.calendarReviewStatsCompletedTasks}**: ${data.completedTaskCount}');
      buffer.writeln('- **${_l10n.calendarReviewFocusSessions}**: ${data.sessionCount}');
      buffer.writeln();

      // 完成任务列表
      if (detail.completedTasks.isNotEmpty) {
        buffer.writeln('#### ${_l10n.calendarReviewTaskList}');
        buffer.writeln();
        for (final task in detail.completedTasks) {
          buffer.writeln('- ${task.title}');
        }
        buffer.writeln();
      }

      // 会话列表
      if (detail.sessions.isNotEmpty) {
        buffer.writeln('#### ${_l10n.calendarReviewFocusSessions}');
        buffer.writeln();
        for (final session in detail.sessions) {
          final duration = CalendarReviewUtils.formatFocusMinutes(session.actualMinutes);
          buffer.writeln('- ${session.startedAt.toIso8601String()}: $duration');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
