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

/// 总计的统计数据
final totalStatisticsProvider = FutureProvider<HomeStatistics>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getTotalStatistics();
});

/// 最佳完成日（三个月内完成任务数量最多的日期）
final topCompletedDateProvider = FutureProvider<TopDateStatistics?>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getTopCompletedDate();
});

/// 最佳专注日（三个月内专注时间最长的日期）
final topFocusDateProvider = FutureProvider<TopDateStatistics?>((ref) async {
  final service = await ref.read(homeStatisticsServiceProvider.future);
  return service.getTopFocusDate();
});

/// 所有统计数据的组合 Provider
final allStatisticsProvider = FutureProvider<AllStatistics>((ref) async {
  // 等待所有统计数据加载完成
  final today = await ref.watch(todayStatisticsProvider.future);
  final thisWeek = await ref.watch(thisWeekStatisticsProvider.future);
  final thisMonth = await ref.watch(thisMonthStatisticsProvider.future);
  final total = await ref.watch(totalStatisticsProvider.future);
  final topCompletedDate = await ref.watch(topCompletedDateProvider.future);
  final topFocusDate = await ref.watch(topFocusDateProvider.future);

  return AllStatistics(
    today: today,
    thisWeek: thisWeek,
    thisMonth: thisMonth,
    total: total,
    topCompletedDate: topCompletedDate,
    topFocusDate: topFocusDate,
  );
});

