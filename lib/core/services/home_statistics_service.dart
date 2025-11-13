import '../../data/models/home_statistics.dart';
import '../../data/repositories/focus_session_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../utils/calendar_review_utils.dart';

/// 首页统计数据服务
class HomeStatisticsService {
  HomeStatisticsService({
    required TaskRepository taskRepository,
    required FocusSessionRepository focusSessionRepository,
  })  : _taskRepository = taskRepository,
        _focusSessionRepository = focusSessionRepository;

  final TaskRepository _taskRepository;
  final FocusSessionRepository _focusSessionRepository;

  /// 获取今天的完成数量和专注时间
  Future<HomeStatistics> getTodayStatistics() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
        start: todayStart,
        end: todayEnd,
      );

      final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
        start: todayStart,
        end: todayEnd,
      );

      final completedCount = tasksByDate.values.fold<int>(
        0,
        (sum, tasks) => sum + tasks.length,
      );

      final focusMinutes = focusMinutesByDate.values.fold<int>(
        0,
        (sum, minutes) => sum + minutes,
      );

      return HomeStatistics(
        completedCount: completedCount,
        focusMinutes: focusMinutes,
      );
    } catch (e) {
      // 错误处理：返回默认值
      return const HomeStatistics(completedCount: 0, focusMinutes: 0);
    }
  }

  /// 获取本周的完成数量和专注时间
  Future<HomeStatistics> getThisWeekStatistics() async {
    try {
      final now = DateTime.now();
      // 使用 CalendarReviewUtils 计算本周的开始和结束时间
      final weekStart = CalendarReviewUtils.getWeekStart(now);
      final weekEnd = CalendarReviewUtils.getWeekEnd(now);

      final startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final endDate = DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59);

      final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
        start: startDate,
        end: endDate,
      );

      final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
        start: startDate,
        end: endDate,
      );

      final completedCount = tasksByDate.values.fold<int>(
        0,
        (sum, tasks) => sum + tasks.length,
      );

      final focusMinutes = focusMinutesByDate.values.fold<int>(
        0,
        (sum, minutes) => sum + minutes,
      );

      return HomeStatistics(
        completedCount: completedCount,
        focusMinutes: focusMinutes,
      );
    } catch (e) {
      // 错误处理：返回默认值
      return const HomeStatistics(completedCount: 0, focusMinutes: 0);
    }
  }

  /// 获取当月的完成数量和专注时间
  Future<HomeStatistics> getThisMonthStatistics() async {
    try {
      final now = DateTime.now();
      // 使用 CalendarReviewUtils 计算当月的开始和结束时间
      final monthStart = CalendarReviewUtils.getMonthStart(now);
      final monthEnd = CalendarReviewUtils.getMonthEnd(now);

      final startDate = DateTime(monthStart.year, monthStart.month, monthStart.day);
      final endDate = DateTime(monthEnd.year, monthEnd.month, monthEnd.day, 23, 59, 59);

      final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
        start: startDate,
        end: endDate,
      );

      final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
        start: startDate,
        end: endDate,
      );

      final completedCount = tasksByDate.values.fold<int>(
        0,
        (sum, tasks) => sum + tasks.length,
      );

      final focusMinutes = focusMinutesByDate.values.fold<int>(
        0,
        (sum, minutes) => sum + minutes,
      );

      return HomeStatistics(
        completedCount: completedCount,
        focusMinutes: focusMinutes,
      );
    } catch (e) {
      // 错误处理：返回默认值
      return const HomeStatistics(completedCount: 0, focusMinutes: 0);
    }
  }

  /// 获取全部的完成数量和专注时间（所有历史数据）
  Future<HomeStatistics> getTotalStatistics() async {
    try {
      // 查询所有历史数据（使用一个很大的日期范围）
      final startDate = DateTime(1970, 1, 1);
      final endDate = DateTime(2100, 1, 1);

      final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
        start: startDate,
        end: endDate,
      );

      final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
        start: startDate,
        end: endDate,
      );

      final completedCount = tasksByDate.values.fold<int>(
        0,
        (sum, tasks) => sum + tasks.length,
      );

      final focusMinutes = focusMinutesByDate.values.fold<int>(
        0,
        (sum, minutes) => sum + minutes,
      );

      return HomeStatistics(
        completedCount: completedCount,
        focusMinutes: focusMinutes,
      );
    } catch (e) {
      // 错误处理：返回默认值
      return const HomeStatistics(completedCount: 0, focusMinutes: 0);
    }
  }

  /// 获取当月完成任务数量最多的日期
  Future<TopDateStatistics?> getThisMonthTopCompletedDate() async {
    try {
      final now = DateTime.now();
      // 使用 CalendarReviewUtils 计算当月的开始和结束时间
      final monthStart = CalendarReviewUtils.getMonthStart(now);
      final monthEnd = CalendarReviewUtils.getMonthEnd(now);

      final startDate = DateTime(monthStart.year, monthStart.month, monthStart.day);
      final endDate = DateTime(monthEnd.year, monthEnd.month, monthEnd.day, 23, 59, 59);

      final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
        start: startDate,
        end: endDate,
      );

      if (tasksByDate.isEmpty) {
        return null;
      }

      // 找到完成数量最多的日期
      DateTime? topDate;
      int maxCount = 0;

      for (final entry in tasksByDate.entries) {
        final count = entry.value.length;
        if (count > maxCount) {
          maxCount = count;
          topDate = entry.key;
        }
      }

      if (topDate == null) {
        return null;
      }

      return TopDateStatistics(
        date: topDate,
        completedCount: maxCount,
      );
    } catch (e) {
      // 错误处理：返回 null
      return null;
    }
  }

  /// 获取当月专注时间最长的日期
  Future<TopDateStatistics?> getThisMonthTopFocusDate() async {
    try {
      final now = DateTime.now();
      // 使用 CalendarReviewUtils 计算当月的开始和结束时间
      final monthStart = CalendarReviewUtils.getMonthStart(now);
      final monthEnd = CalendarReviewUtils.getMonthEnd(now);

      final startDate = DateTime(monthStart.year, monthStart.month, monthStart.day);
      final endDate = DateTime(monthEnd.year, monthEnd.month, monthEnd.day, 23, 59, 59);

      final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
        start: startDate,
        end: endDate,
      );

      if (focusMinutesByDate.isEmpty) {
        return null;
      }

      // 找到专注时间最长的日期
      DateTime? topDate;
      int maxMinutes = -1; // 初始化为 -1，确保即使专注时间为 0 也能找到日期

      for (final entry in focusMinutesByDate.entries) {
        final minutes = entry.value;
        if (minutes > maxMinutes) {
          maxMinutes = minutes;
          topDate = entry.key;
        }
      }

      if (topDate == null) {
        return null;
      }

      return TopDateStatistics(
        date: topDate,
        focusMinutes: maxMinutes,
      );
    } catch (e) {
      // 错误处理：返回 null
      return null;
    }
  }

  /// 获取历史完成任务数量最多的日期
  Future<TopDateStatistics?> getTotalTopCompletedDate() async {
    try {
      // 查询所有历史数据（使用一个很大的日期范围）
      final startDate = DateTime(1970, 1, 1);
      final endDate = DateTime(2100, 1, 1);

      final tasksByDate = await _taskRepository.getCompletedRootTasksByDateRange(
        start: startDate,
        end: endDate,
      );

      if (tasksByDate.isEmpty) {
        return null;
      }

      // 找到完成数量最多的日期
      DateTime? topDate;
      int maxCount = 0;

      for (final entry in tasksByDate.entries) {
        final count = entry.value.length;
        if (count > maxCount) {
          maxCount = count;
          topDate = entry.key;
        }
      }

      if (topDate == null) {
        return null;
      }

      return TopDateStatistics(
        date: topDate,
        completedCount: maxCount,
      );
    } catch (e) {
      // 错误处理：返回 null
      return null;
    }
  }

  /// 获取历史专注时间最长的日期
  Future<TopDateStatistics?> getTotalTopFocusDate() async {
    try {
      // 查询所有历史数据（使用一个很大的日期范围）
      final startDate = DateTime(1970, 1, 1);
      final endDate = DateTime(2100, 1, 1);

      final focusMinutesByDate = await _focusSessionRepository.getFocusMinutesByDateRange(
        start: startDate,
        end: endDate,
      );

      if (focusMinutesByDate.isEmpty) {
        return null;
      }

      // 找到专注时间最长的日期
      DateTime? topDate;
      int maxMinutes = -1; // 初始化为 -1，确保即使专注时间为 0 也能找到日期

      for (final entry in focusMinutesByDate.entries) {
        final minutes = entry.value;
        if (minutes > maxMinutes) {
          maxMinutes = minutes;
          topDate = entry.key;
        }
      }

      if (topDate == null) {
        return null;
      }

      return TopDateStatistics(
        date: topDate,
        focusMinutes: maxMinutes,
      );
    } catch (e) {
      // 错误处理：返回 null
      return null;
    }
  }
}

