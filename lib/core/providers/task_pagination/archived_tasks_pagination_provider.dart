import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../../data/repositories/task_repository.dart';
import '../repository_providers.dart';
import '../task_filter_providers.dart';

/// 已归档任务分页状态
@immutable
class ArchivedTasksPaginationState {
  const ArchivedTasksPaginationState({
    this.tasks = const <Task>[],
    this.isLoading = false,
    this.hasMore = true,
    this.totalCount = 0,
  });

  final List<Task> tasks;
  final bool isLoading;
  final bool hasMore;
  final int totalCount;

  ArchivedTasksPaginationState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? hasMore,
    int? totalCount,
  }) {
    return ArchivedTasksPaginationState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// 已归档任务分页 Notifier
class ArchivedTasksPaginationNotifier
    extends StateNotifier<ArchivedTasksPaginationState> {
  ArchivedTasksPaginationNotifier(this.ref)
      : super(const ArchivedTasksPaginationState()) {
    debugPrint('[ArchivedPagination] Notifier created');
  }

  final Ref ref;
  static const int _pageSize = 30;

  Future<TaskRepository> get _repository async => await ref.read(taskRepositoryProvider.future);

  /// 加载初始数据
  Future<void> loadInitial() async {
    if (state.isLoading) {
      debugPrint('[ArchivedPagination] loadInitial: Already loading, skipping');
      return;
    }

    debugPrint('[ArchivedPagination] loadInitial: Starting load');
    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(archivedTasksFilterProvider);
      
      final repository = await _repository;
      final tasks = await repository.listArchivedTasks(
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
      final totalCount = await repository.countArchivedTasks();

      debugPrint(
        '[ArchivedPagination] loadInitial: Loaded ${tasks.length} tasks, totalCount=$totalCount',
      );

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        hasMore: tasks.length < totalCount,
        totalCount: totalCount,
      );

      debugPrint(
        '[ArchivedPagination] loadInitial: State updated - tasks=${state.tasks.length}, hasMore=${state.hasMore}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[ArchivedPagination] loadInitial: Failed - $error\n$stackTrace',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  /// 加载更多数据
  Future<void> loadMore() async {
    if (state.isLoading) {
      debugPrint('[ArchivedPagination] loadMore: Already loading, skipping');
      return;
    }
    if (!state.hasMore) {
      debugPrint('[ArchivedPagination] loadMore: No more data, skipping');
      return;
    }

    debugPrint(
      '[ArchivedPagination] loadMore: Loading more, currentCount=${state.tasks.length}',
    );
    state = state.copyWith(isLoading: true);

    try {
      // 读取筛选条件
      final filter = ref.read(archivedTasksFilterProvider);
      
      final tasks = await _repository.listArchivedTasks(
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

      debugPrint(
        '[ArchivedPagination] loadMore: Loaded ${tasks.length} more tasks',
      );

      state = state.copyWith(
        tasks: [...state.tasks, ...tasks],
        isLoading: false,
        hasMore: tasks.length == _pageSize,
      );

      debugPrint(
        '[ArchivedPagination] loadMore: State updated - tasks=${state.tasks.length}, hasMore=${state.hasMore}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[ArchivedPagination] loadMore: Failed - $error\n$stackTrace',
      );
      state = state.copyWith(isLoading: false);
    }
  }
}

final archivedTasksPaginationProvider = StateNotifierProvider<
    ArchivedTasksPaginationNotifier, ArchivedTasksPaginationState>((ref) {
  return ArchivedTasksPaginationNotifier(ref);
});

