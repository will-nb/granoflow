import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/calendar_review_data.dart';
import '../services/calendar_review_service.dart';
import 'service_providers.dart';

/// 日历回顾页面状态
@immutable
class CalendarReviewState {
  const CalendarReviewState({
    this.isLoading = false,
    this.dailyData = const <DateTime, DayReviewData>{},
    this.selectedDate,
    this.viewMode = CalendarViewMode.month,
    this.filter = const CalendarFilter(),
    this.error,
  });

  final bool isLoading;
  final Map<DateTime, DayReviewData> dailyData;
  final DateTime? selectedDate;
  final CalendarViewMode viewMode;
  final CalendarFilter filter;
  final String? error;

  CalendarReviewState copyWith({
    bool? isLoading,
    Map<DateTime, DayReviewData>? dailyData,
    DateTime? selectedDate,
    CalendarViewMode? viewMode,
    CalendarFilter? filter,
    String? error,
    bool clearError = false,
  }) {
    return CalendarReviewState(
      isLoading: isLoading ?? this.isLoading,
      dailyData: dailyData ?? this.dailyData,
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      filter: filter ?? this.filter,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 视图模式枚举
enum CalendarViewMode {
  day,
  week,
  month,
}

/// 日历回顾状态管理 Notifier
class CalendarReviewNotifier extends StateNotifier<CalendarReviewState> {
  CalendarReviewNotifier(this.ref)
      : super(const CalendarReviewState()) {
    _loadPersistedFilter();
  }

  final Ref ref;

  static const String _keyProjectId = 'calendar_review_project_id';
  static const String _keyTags = 'calendar_review_tags';

  Future<CalendarReviewService> get _service async =>
      await ref.read(calendarReviewServiceProvider.future);

  /// 加载持久化的筛选条件
  Future<void> _loadPersistedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectId = prefs.getString(_keyProjectId);
      final tagsJson = prefs.getString(_keyTags);
      
      List<String> tags = [];
      if (tagsJson != null) {
        try {
          final tagsList = jsonDecode(tagsJson) as List;
          tags = tagsList.cast<String>();
        } catch (e) {
          // 解析失败，使用空列表
        }
      }

      if (projectId != null || tags.isNotEmpty) {
        state = state.copyWith(
          filter: CalendarFilter(
            projectId: projectId,
            tags: tags,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to load persisted filter: $e');
    }
  }

  /// 保存筛选条件到持久化存储
  Future<void> _saveFilter(CalendarFilter filter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (filter.projectId != null) {
        await prefs.setString(_keyProjectId, filter.projectId!);
      } else {
        await prefs.remove(_keyProjectId);
      }

      if (filter.tags.isNotEmpty) {
        await prefs.setString(_keyTags, jsonEncode(filter.tags));
      } else {
        await prefs.remove(_keyTags);
      }
    } catch (e) {
      debugPrint('Failed to save filter: $e');
    }
  }

  /// 加载日期范围的数据（懒加载）
  Future<void> loadDailyData({
    required DateTime start,
    required DateTime end,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final service = await _service;
      final dailyData = await service.loadDailyData(
        start: start,
        end: end,
        filter: state.filter,
      );

      // 合并到现有数据中
      final mergedData = Map<DateTime, DayReviewData>.from(state.dailyData);
      mergedData.addAll(dailyData);

      state = state.copyWith(
        dailyData: mergedData,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to load daily data: $e\n$stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 设置筛选条件并重新加载数据
  Future<void> setFilter(CalendarFilter filter) async {
    state = state.copyWith(
      filter: filter,
      dailyData: {}, // 清空现有数据，重新加载
      clearError: true,
    );

    await _saveFilter(filter);
  }

  /// 切换视图模式
  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// 选择日期
  void selectDate(DateTime? date) {
    state = state.copyWith(selectedDate: date);
  }
}

/// 日历回顾状态 Provider
final calendarReviewNotifierProvider =
    StateNotifierProvider<CalendarReviewNotifier, CalendarReviewState>((ref) {
  return CalendarReviewNotifier(ref);
});

/// 日历数据 Provider（StreamProvider，提供响应式数据流）
/// 
/// 根据当前视图模式和选中日期，提供对应的数据
final calendarDataProvider = StreamProvider.autoDispose<Map<DateTime, DayReviewData>>((ref) async* {
  final state = ref.watch(calendarReviewNotifierProvider);
  yield state.dailyData;
});

/// 日期详情 Provider（FutureProvider.family）
/// 
/// 提供指定日期的详细数据
final dayDetailProvider = FutureProvider.autoDispose.family<DayDetailData, DateTime>((ref, date) async {
  final state = ref.watch(calendarReviewNotifierProvider);
  final service = await ref.read(calendarReviewServiceProvider.future);
  
  return service.loadDayDetail(
    date: date,
    filter: state.filter,
  );
});

/// 周数据 Provider（FutureProvider.family）
/// 
/// 提供指定日期所在周的统计数据
final weekDataProvider = FutureProvider.autoDispose.family<WeekReviewData, DateTime>((ref, date) async {
  final state = ref.watch(calendarReviewNotifierProvider);
  final service = await ref.read(calendarReviewServiceProvider.future);
  
  return service.loadWeekData(
    date: date,
    filter: state.filter,
  );
});

/// 月数据 Provider（FutureProvider.family）
/// 
/// 提供指定日期所在月的统计数据
final monthDataProvider = FutureProvider.autoDispose.family<MonthReviewData, DateTime>((ref, date) async {
  final state = ref.watch(calendarReviewNotifierProvider);
  final service = await ref.read(calendarReviewServiceProvider.future);
  
  return service.loadMonthData(
    date: date,
    filter: state.filter,
  );
});
