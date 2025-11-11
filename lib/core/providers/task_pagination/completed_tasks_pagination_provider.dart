import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../repository_providers.dart';
import '../task_filter_providers.dart';

/// 已完成任务分页状态
@immutable
class CompletedTasksPaginationState {
  const CompletedTasksPaginationState({
    this.tasks = const <Task>[],
    this.isLoading = false,
    this.hasMore = true,
    this.totalCount = 0,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool hasMore;
  final int totalCount;

  CompletedTasksPaginationState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? hasMore,
    int? totalCount,
  }) {
    return CompletedTasksPaginationState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// 已完成任务分页 Notifier
class CompletedTasksPaginationNotifier
    extends StateNotifier<CompletedTasksPaginationState> {
  CompletedTasksPaginationNotifier(this.ref)
      : super(const CompletedTasksPaginationState());

  final Ref ref;
  static const int _pageSize = 30;

  Future<TaskRepository> get _repository async => await ref.read(taskRepositoryProvider.future);

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(completedTasksFilterProvider);
      
      final repository = await _repository;
      final tasks = await repository.listCompletedTasks(
        limit: _pageSize,
        offset: 0,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );
      final totalCount = await repository.countCompletedTasks();

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        hasMore: tasks.length < totalCount,
        totalCount: totalCount,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load completed tasks: $error\n$stackTrace');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(completedTasksFilterProvider);
      
      final repository = await _repository;
      final tasks = await repository.listCompletedTasks(
        limit: _pageSize,
        offset: state.tasks.length,
        contextTag: filter.contextTag,
        priorityTag: null, // priorityTag 已废弃，不再使用
        urgencyTag: filter.urgencyTag,
        importanceTag: filter.importanceTag,
        projectId: filter.projectId,
        milestoneId: filter.milestoneId,
        showNoProject: filter.showNoProject,
      );

      state = state.copyWith(
        tasks: [...state.tasks, ...tasks],
        isLoading: false,
        hasMore: tasks.length == _pageSize,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to load more completed tasks: $error\n$stackTrace');
      state = state.copyWith(isLoading: false);
    }
  }
}

final completedTasksPaginationProvider = StateNotifierProvider<
    CompletedTasksPaginationNotifier, CompletedTasksPaginationState>((ref) {
  return CompletedTasksPaginationNotifier(ref);
});

