import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/review_data.dart';
import '../services/review_data_service.dart';
import 'service_providers.dart';

/// 回顾页面状态
class ReviewPageState {
  const ReviewPageState({
    this.loading = false,
    this.data,
    this.error,
    this.animationCompleted = false,
    this.contentDisplayIndex = 0,
    this.allContentDisplayed = false,
  });

  /// 是否正在加载
  final bool loading;

  /// 所有回顾数据
  final ReviewData? data;

  /// 错误信息
  final String? error;

  /// 开场动画是否完成
  final bool animationCompleted;

  /// 当前显示到第几行内容（从0开始）
  final int contentDisplayIndex;

  /// 所有内容是否已显示完成
  final bool allContentDisplayed;

  ReviewPageState copyWith({
    bool? loading,
    ReviewData? data,
    String? error,
    bool? animationCompleted,
    int? contentDisplayIndex,
    bool? allContentDisplayed,
  }) {
    return ReviewPageState(
      loading: loading ?? this.loading,
      data: data ?? this.data,
      error: error ?? this.error,
      animationCompleted: animationCompleted ?? this.animationCompleted,
      contentDisplayIndex: contentDisplayIndex ?? this.contentDisplayIndex,
      allContentDisplayed: allContentDisplayed ?? this.allContentDisplayed,
    );
  }
}

/// 回顾页面状态管理
class ReviewPageNotifier extends StateNotifier<ReviewPageState> {
  ReviewPageNotifier({
    required ReviewDataService reviewDataService,
  })  : _reviewDataService = reviewDataService,
        super(const ReviewPageState());

  final ReviewDataService _reviewDataService;

  /// 加载所有数据
  Future<void> loadData() async {
    state = state.copyWith(loading: true, error: null);

    try {
      final data = await _reviewDataServiceOrThrow.loadAllReviewData();
      state = state.copyWith(
        loading: false,
        data: data,
        error: null,
      );
    } catch (error, stackTrace) {
      // 输出详细错误信息到控制台
      debugPrint('ReviewPageNotifier: Failed to load review data');
      debugPrint('ReviewPageNotifier: Error: $error');
      debugPrint('ReviewPageNotifier: Stack trace: $stackTrace');
      state = state.copyWith(
        loading: false,
        error: error.toString(),
      );
    }
  }

  /// 开场动画完成回调
  void onAnimationComplete() {
    state = state.copyWith(animationCompleted: true);
  }

  /// 显示下一行内容
  void displayNextLine() {
    final currentIndex = state.contentDisplayIndex;
    final totalLines = _calculateTotalLines(state.data);

    if (currentIndex < totalLines - 1) {
      state = state.copyWith(contentDisplayIndex: currentIndex + 1);
    } else {
      // 所有内容已显示完成
      state = state.copyWith(
        contentDisplayIndex: totalLines,
        allContentDisplayed: true,
      );
    }
  }

  /// 计算总行数
  int _calculateTotalLines(ReviewData? data) {
    if (data == null) {
      return 0;
    }

    int count = 2; // 欢迎语 + 统计信息

    // 新用户提示
    if (_shouldShowNewUserHint(data)) {
      count++;
    }

    // 项目相关行
    if (data.stats.projectCount == 0) {
      count++; // 没有项目提示
    } else {
      final activeProjectCount = data.projects.length;
      if (activeProjectCount > 0) {
        count++; // 项目数量行
        count += data.projects.length; // 项目列表
      }
    }

    // 独立任务统计
    if (data.standaloneTasks.totalCount > 0) {
      count++;
    }

    // 最长已完成任务
    if (data.longestCompletedTask != null &&
        data.longestCompletedTask!.totalMinutes >= 120) {
      count++; // 任务信息行
      count++; // 完成消息行
      if (data.longestCompletedTask!.task.description != null &&
          data.longestCompletedTask!.task.description!.isNotEmpty) {
        count++; // 任务分析行
      }
      count += data.longestCompletedTask!.subtasks.length; // 子任务列表
    } else {
      count++; // 没有长任务提示
    }

    // 完成根任务最多的一天
    if (data.mostCompletedDay != null) {
      count++;
    }

    // 最长归档任务
    if (data.longestArchivedTask != null &&
        data.longestArchivedTask!.totalMinutes > 0) {
      count++; // 任务信息行
      count++; // 归档消息行
    }

    // 结束语
    count++;

    return count;
  }

  /// 判断是否应该显示新用户提示
  bool _shouldShowNewUserHint(ReviewData data) {
    return data.stats.projectCount <= 3 ||
        data.stats.taskCount <= 300 ||
        data.welcome.dayCount <= 90;
  }
}

/// 回顾页面状态 Provider
final reviewPageProvider =
    StateNotifierProvider<ReviewPageNotifier, ReviewPageState>((ref) {
  // 注意：StateNotifierProvider 不能是 async，所以我们需要在 StateNotifier 内部处理异步初始化
  // ReviewPageNotifier 需要在内部异步获取依赖
  return ReviewPageNotifier._(ref);
});

