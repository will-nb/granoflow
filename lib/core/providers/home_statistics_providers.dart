import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/home_statistics.dart';
import 'service_providers.dart';

/// 今天的统计数据
final todayStatisticsProvider = FutureProvider<HomeStatistics>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getTodayStatistics();
});

/// 本周的统计数据
final thisWeekStatisticsProvider = FutureProvider<HomeStatistics>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getThisWeekStatistics();
});

/// 当月的统计数据
final thisMonthStatisticsProvider = FutureProvider<HomeStatistics>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getThisMonthStatistics();
});

/// 全部的统计数据（所有历史数据）
final totalStatisticsProvider = FutureProvider<HomeStatistics>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getTotalStatistics();
});

/// 当月最佳完成日（当月完成任务数量最多的日期）
final thisMonthTopCompletedDateProvider = FutureProvider<TopDateStatistics?>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getThisMonthTopCompletedDate();
});

/// 当月最佳专注日（当月专注时间最长的日期）
final thisMonthTopFocusDateProvider = FutureProvider<TopDateStatistics?>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getThisMonthTopFocusDate();
});

/// 历史最佳完成日（历史完成任务数量最多的日期）
final totalTopCompletedDateProvider = FutureProvider<TopDateStatistics?>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getTotalTopCompletedDate();
});

/// 历史最佳专注日（历史专注时间最长的日期）
final totalTopFocusDateProvider = FutureProvider<TopDateStatistics?>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getTotalTopFocusDate();
});

/// 所有统计数据的组合 Provider
final allStatisticsProvider = FutureProvider<AllStatistics>((ref) async {
  // 等待所有统计数据加载完成
  final today = await ref.watch(todayStatisticsProvider.future);
  final thisWeek = await ref.watch(thisWeekStatisticsProvider.future);
  final thisMonth = await ref.watch(thisMonthStatisticsProvider.future);
  final total = await ref.watch(totalStatisticsProvider.future);
  final thisMonthTopCompletedDate = await ref.watch(thisMonthTopCompletedDateProvider.future);
  final thisMonthTopFocusDate = await ref.watch(thisMonthTopFocusDateProvider.future);
  final totalTopCompletedDate = await ref.watch(totalTopCompletedDateProvider.future);
  final totalTopFocusDate = await ref.watch(totalTopFocusDateProvider.future);

  return AllStatistics(
    today: today,
    thisWeek: thisWeek,
    thisMonth: thisMonth,
    total: total,
    thisMonthTopCompletedDate: thisMonthTopCompletedDate,
    thisMonthTopFocusDate: thisMonthTopFocusDate,
    totalTopCompletedDate: totalTopCompletedDate,
    totalTopFocusDate: totalTopFocusDate,
  );
});

