import 'package:flutter/foundation.dart';
import '../../data/models/calendar_review_data.dart';
import '../../data/models/focus_session.dart';
import '../../data/models/task.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../utils/calendar_review_utils.dart';

/// 日历回顾数据查询服务
/// 封装数据聚合逻辑和筛选逻辑
class CalendarReviewService {
  CalendarReviewService({
    required TaskRepository taskRepository,
    required FocusSessionRepository focusSessionRepository,
  })  : _taskRepository = taskRepository,
        _focusSessionRepository = focusSessionRepository;

  final TaskRepository _taskRepository;
  final FocusSessionRepository _focusSessionRepository;

  /// 获取日期范围内的每日数据（懒加载）
  /// 
  /// [start] 开始日期
  /// [end] 结束日期
  /// [filter] 筛选条件
  /// 返回 Map<日期, DayReviewData>
  Future<Map<DateTime, DayReviewData>> loadDailyData({
    required DateTime start,
    required DateTime end,
    CalendarFilter filter = const CalendarFilter(),
  }) async {
    // 规范化日期：只保留年月日
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    debugPrint('CalendarReviewService.loadDailyData:');
    debugPrint('  Date range: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    debugPrint('  Filter: projectId=${filter.projectId}, tags=${filter.tags}');

    // 调试：检查数据库中的总任务数
    final allTasks = await _taskRepository.listAll();
    final rootTasks = allTasks.where((t) => t.parentId == null).toList();
    final completedTasks = allTasks.where((t) => t.status == TaskStatus.completedActive).toList();
    final rootCompletedTasks = rootTasks.where((t) => t.status == TaskStatus.completedActive).toList();
    debugPrint('  Debug: Total tasks: ${allTasks.length}, Root tasks: ${rootTasks.length}');
    debugPrint('  Debug: Completed tasks: ${completedTasks.length}, Root completed: ${rootCompletedTasks.length}');
    if (rootCompletedTasks.isNotEmpty) {
      debugPrint('  Debug: Root completed tasks with endedAt:');
      for (final task in rootCompletedTasks.take(5)) {
        debugPrint('    - ${task.title}: endedAt=${task.endedAt?.toIso8601String()}, status=${task.status}');
      }
    }

    // 获取符合条件的根任务ID列表（用于筛选焦点会话）
    final filteredTaskIds = await _getFilteredRootTaskIds(
      start: startDate,
      end: endDate,
      filter: filter,
    );

    debugPrint('  Filtered task IDs: ${filteredTaskIds.length} tasks');

    // 并行查询任务和会话数据
    final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
      start: startDate,
      end: endDate,
      projectId: filter.projectId,
      tags: filter.tags.isEmpty ? null : filter.tags,
    );

    debugPrint('  Completed tasks: ${tasksByDate.length} dates, ${tasksByDate.values.fold<int>(0, (sum, tasks) => sum + tasks.length)} total tasks');
    if (tasksByDate.isNotEmpty) {
      debugPrint('  Debug: Completed tasks by date:');
      for (final entry in tasksByDate.entries.take(5)) {
        debugPrint('    - ${entry.key.toIso8601String()}: ${entry.value.length} tasks');
        for (final task in entry.value.take(2)) {
          debugPrint('      * ${task.title}: endedAt=${task.endedAt?.toIso8601String()}');
        }
      }
    }

    final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
      start: startDate,
      end: endDate,
      taskIds: filteredTaskIds.isEmpty ? null : filteredTaskIds,
    );

    debugPrint('  Focus minutes: ${focusMinutesByDate.length} dates, ${focusMinutesByDate.values.fold<int>(0, (sum, minutes) => sum + minutes)} total minutes');

    // 聚合数据
    final result = <DateTime, DayReviewData>{};
    
    // 获取所有会话（一次性查询，避免 N+1 问题）
    final allSessions = await _focusSessionRepository.listSessionsByDateRange(
      start: startDate,
      end: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      taskIds: filteredTaskIds.isEmpty ? null : filteredTaskIds,
    );

    debugPrint('  Focus sessions: ${allSessions.length} total sessions');
    if (allSessions.isNotEmpty) {
      debugPrint('  Debug: Sample sessions:');
      for (final session in allSessions.take(3)) {
        debugPrint('    - Session ${session.id}: endedAt=${session.endedAt?.toIso8601String()}, taskId=${session.taskId}, minutes=${session.actualMinutes}');
      }
    }
    
    // 按日期分组会话
    final sessionsByDate = <DateTime, List<FocusSession>>{};
    for (final session in allSessions) {
      if (session.endedAt == null) continue;
      final date = DateTime(
        session.endedAt!.year,
        session.endedAt!.month,
        session.endedAt!.day,
      );
      sessionsByDate.putIfAbsent(date, () => []).add(session);
    }
    
    debugPrint('  Debug: Sessions by date: ${sessionsByDate.length} dates');
    for (final entry in sessionsByDate.entries.take(3)) {
      debugPrint('    - ${entry.key.toIso8601String()}: ${entry.value.length} sessions');
    }
    
    // 遍历日期范围
    var currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final tasks = tasksByDate[currentDate] ?? [];
      final focusMinutes = focusMinutesByDate[currentDate] ?? 0;
      final sessions = sessionsByDate[currentDate] ?? [];

      result[currentDate] = DayReviewData(
        date: currentDate,
        focusMinutes: focusMinutes,
        completedTaskCount: tasks.length,
        sessionCount: sessions.length,
      );

      // 移动到下一天
      currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day + 1);
    }

    debugPrint('  Result: ${result.length} dates with data');
    for (final entry in result.entries) {
      if (entry.value.focusMinutes > 0 || entry.value.completedTaskCount > 0 || entry.value.sessionCount > 0) {
        debugPrint('    ${entry.key.toIso8601String()}: ${entry.value.focusMinutes}m, ${entry.value.completedTaskCount} tasks, ${entry.value.sessionCount} sessions');
      }
    }

    return result;
  }

  /// 获取指定日期的详细数据
  /// 
  /// [date] 日期
  /// [filter] 筛选条件
  /// 返回 DayDetailData
  Future<DayDetailData> loadDayDetail({
    required DateTime date,
    CalendarFilter filter = const CalendarFilter(),
  }) async {
    // 规范化日期：只保留年月日
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // 获取符合条件的根任务ID列表
    final filteredTaskIds = await _getFilteredRootTaskIds(
      start: dateStart,
      end: dateEnd,
      filter: filter,
    );

    // 查询任务和会话
    final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
      start: dateStart,
      end: dateEnd,
      projectId: filter.projectId,
      tags: filter.tags.isEmpty ? null : filter.tags,
    );

    final sessions = await _focusSessionRepository.listSessionsByDateRange(
      start: dateStart,
      end: dateEnd,
      taskIds: filteredTaskIds.isEmpty ? null : filteredTaskIds,
    );

    final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
      start: dateStart,
      end: dateEnd,
      taskIds: filteredTaskIds.isEmpty ? null : filteredTaskIds,
    );

    final tasks = tasksByDate[dateStart] ?? [];
    final focusMinutes = focusMinutesByDate[dateStart] ?? 0;

    return DayDetailData(
      date: dateStart,
      focusMinutes: focusMinutes,
      completedTasks: tasks,
      sessions: sessions,
    );
  }

  /// 获取周统计数据
  /// 
  /// [date] 周内的任意日期
  /// [filter] 筛选条件
  /// 返回 WeekReviewData
  Future<WeekReviewData> loadWeekData({
    required DateTime date,
    CalendarFilter filter = const CalendarFilter(),
  }) async {
    final weekStart = CalendarReviewUtils.getWeekStart(date);
    final weekEnd = CalendarReviewUtils.getWeekEnd(date);

    final dailyData = await loadDailyData(
      start: weekStart,
      end: weekEnd,
      filter: filter,
    );

    final totalFocusMinutes = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.focusMinutes);
    final totalCompletedTasks = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.completedTaskCount);
    final totalSessions = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.sessionCount);
    
    final daysCount = dailyData.length;
    final averageDailyMinutes = daysCount > 0 ? totalFocusMinutes ~/ daysCount : 0;

    return WeekReviewData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalFocusMinutes: totalFocusMinutes,
      completedTaskCount: totalCompletedTasks,
      averageDailyMinutes: averageDailyMinutes,
      sessionCount: totalSessions,
    );
  }

  /// 获取周详细数据（一周内每天的详细数据）
  /// 
  /// [date] 周内的任意日期
  /// [filter] 筛选条件
  /// 返回 Map<日期, DayDetailData>
  Future<Map<DateTime, DayDetailData>> loadWeekDetail({
    required DateTime date,
    CalendarFilter filter = const CalendarFilter(),
  }) async {
    final weekStart = CalendarReviewUtils.getWeekStart(date);
    final weekEnd = CalendarReviewUtils.getWeekEnd(date);

    // 规范化日期：只保留年月日
    final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final endDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

    // 获取符合条件的根任务ID列表
    final filteredTaskIds = await _getFilteredRootTaskIds(
      start: startDate,
      end: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      filter: filter,
    );

    // 查询任务和会话
    final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
      start: startDate,
      end: endDate,
      projectId: filter.projectId,
      tags: filter.tags.isEmpty ? null : filter.tags,
    );

    final sessions = await _focusSessionRepository.listSessionsByDateRange(
      start: startDate,
      end: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      taskIds: filteredTaskIds.isEmpty ? null : filteredTaskIds,
    );

    final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
      start: startDate,
      end: endDate,
      taskIds: filteredTaskIds.isEmpty ? null : filteredTaskIds,
    );

    // 按日期分组会话
    final sessionsByDate = <DateTime, List<FocusSession>>{};
    for (final session in sessions) {
      if (session.endedAt == null) continue;
      final date = DateTime(
        session.endedAt!.year,
        session.endedAt!.month,
        session.endedAt!.day,
      );
      sessionsByDate.putIfAbsent(date, () => []).add(session);
    }

    // 构建结果：一周内每天的详细数据
    final result = <DateTime, DayDetailData>{};
    var currentDate = startDate;
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      final tasks = tasksByDate[currentDate] ?? [];
      final focusMinutes = focusMinutesByDate[currentDate] ?? 0;
      final daySessions = sessionsByDate[currentDate] ?? [];

      result[currentDate] = DayDetailData(
        date: currentDate,
        focusMinutes: focusMinutes,
        completedTasks: tasks,
        sessions: daySessions,
      );

      // 移动到下一天
      currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day + 1);
    }

    return result;
  }

  /// 获取月统计数据
  /// 
  /// [date] 月内的任意日期
  /// [filter] 筛选条件
  /// 返回 MonthReviewData
  Future<MonthReviewData> loadMonthData({
    required DateTime date,
    CalendarFilter filter = const CalendarFilter(),
  }) async {
    final monthStart = CalendarReviewUtils.getMonthStart(date);
    final monthEnd = CalendarReviewUtils.getMonthEnd(date);

    final dailyData = await loadDailyData(
      start: monthStart,
      end: monthEnd,
      filter: filter,
    );

    final totalFocusMinutes = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.focusMinutes);
    final totalCompletedTasks = dailyData.values
        .fold<int>(0, (sum, data) => sum + data.completedTaskCount);
    
    final daysCount = dailyData.length;
    final averageDailyMinutes = daysCount > 0 ? totalFocusMinutes ~/ daysCount : 0;

    // 找到最活跃的日期（专注时长最多的日期）
    DateTime? mostActiveDate;
    int maxMinutes = 0;
    for (final entry in dailyData.entries) {
      if (entry.value.focusMinutes > maxMinutes) {
        maxMinutes = entry.value.focusMinutes;
        mostActiveDate = entry.key;
      }
    }

    return MonthReviewData(
      year: date.year,
      month: date.month,
      totalFocusMinutes: totalFocusMinutes,
      completedTaskCount: totalCompletedTasks,
      averageDailyMinutes: averageDailyMinutes,
      mostActiveDate: mostActiveDate,
    );
  }

  /// 根据筛选条件获取符合条件的根任务ID列表
  /// 
  /// 用于筛选焦点会话，确保只统计符合条件的任务的会话
  /// 如果没有筛选条件，返回空列表（表示不过滤，查询所有任务的会话）
  /// 如果有筛选条件，查询所有符合条件的根任务（不限制状态和日期），用于筛选焦点会话
  Future<List<String>> _getFilteredRootTaskIds({
    required DateTime start,
    required DateTime end,
    required CalendarFilter filter,
  }) async {
    // 如果没有筛选条件，返回空列表（表示不过滤，查询所有任务的会话）
    if (filter.isEmpty) {
      return [];
    }

    // 有筛选条件时，需要查询所有符合条件的根任务（不限制状态和日期）
    // 因为焦点会话可能属于任何状态的任务，只要任务符合筛选条件即可
    final allTasks = await _taskRepository.listAll();
    
    // 筛选根任务，排除指定状态
    var rootTasks = allTasks.where((task) =>
        task.parentId == null &&
        task.status != TaskStatus.inbox &&
        task.status != TaskStatus.trashed &&
        task.status != TaskStatus.pseudoDeleted &&
        task.status != TaskStatus.archived);
    
    // 应用项目筛选
    if (filter.projectId != null) {
      rootTasks = rootTasks.where((task) => task.projectId == filter.projectId);
    }
    
    // 应用标签筛选
    if (filter.tags.isNotEmpty) {
      rootTasks = rootTasks.where((task) {
        return filter.tags.every((tag) => task.tags.contains(tag));
      });
    }
    
    return rootTasks.map((task) => task.id).toList();
  }

  /// 生成 Markdown 格式的导出内容
  /// 
  /// [start] 开始日期
  /// [end] 结束日期
  /// [filter] 筛选条件
  /// [viewMode] 视图模式（用于元信息）
  /// 返回 Markdown 字符串
  Future<String> generateMarkdownExport({
    required DateTime start,
    required DateTime end,
    CalendarFilter filter = const CalendarFilter(),
    String viewMode = 'Calendar',
  }) async {
    final dailyData = await loadDailyData(
      start: start,
      end: end,
      filter: filter,
    );

    final buffer = StringBuffer();
    
    // 标题
    buffer.writeln('# Calendar Review Export');
    buffer.writeln();
    
    // 元信息
    buffer.writeln('## Metadata');
    buffer.writeln();
    buffer.writeln('- **Export Time**: ${DateTime.now().toIso8601String()}');
    buffer.writeln('- **Date Range**: ${start.toIso8601String()} to ${end.toIso8601String()}');
    buffer.writeln('- **View Mode**: $viewMode');
    buffer.writeln();
    
    // 筛选条件
    if (!filter.isEmpty) {
      buffer.writeln('## Filter');
      buffer.writeln();
      if (filter.projectId != null) {
        buffer.writeln('- **Project ID**: ${filter.projectId}');
      }
      if (filter.tags.isNotEmpty) {
        buffer.writeln('- **Tags**: ${filter.tags.join(", ")}');
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
    buffer.writeln('- **Total Focus Time**: ${CalendarReviewUtils.formatFocusMinutes(totalFocusMinutes)}');
    buffer.writeln('- **Total Completed Tasks**: $totalCompletedTasks');
    buffer.writeln('- **Total Sessions**: $totalSessions');
    buffer.writeln();
    
    // 每日详情
    buffer.writeln('## Daily Details');
    buffer.writeln();
    
    final sortedDates = dailyData.keys.toList()..sort();
    for (final date in sortedDates) {
      final data = dailyData[date]!;
      final detail = await loadDayDetail(date: date, filter: filter);
      
      buffer.writeln('### ${date.toIso8601String().split('T')[0]}');
      buffer.writeln();
      buffer.writeln('- **Focus Time**: ${CalendarReviewUtils.formatFocusMinutes(data.focusMinutes)}');
      buffer.writeln('- **Completed Tasks**: ${data.completedTaskCount}');
      buffer.writeln('- **Sessions**: ${data.sessionCount}');
      buffer.writeln();
      
      // 完成任务列表
      if (detail.completedTasks.isNotEmpty) {
        buffer.writeln('#### Completed Tasks');
        buffer.writeln();
        for (final task in detail.completedTasks) {
          buffer.writeln('- ${task.title}');
        }
        buffer.writeln();
      }
      
      // 会话列表
      if (detail.sessions.isNotEmpty) {
        buffer.writeln('#### Focus Sessions');
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
