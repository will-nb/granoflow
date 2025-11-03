import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';

/// 分页任务列表组件
/// 
/// 支持自动加载更多，当滚动接近底部时自动触发加载
class PaginatedTaskList extends ConsumerStatefulWidget {
  const PaginatedTaskList({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.itemBuilder,
  });

  /// 当前已加载的任务列表
  final List<Task> tasks;

  /// 是否正在加载
  final bool isLoading;

  /// 是否还有更多数据
  final bool hasMore;

  /// 加载更多的回调
  final VoidCallback onLoadMore;

  /// 构建每个任务项的 widget
  final Widget Function(BuildContext, Task, int) itemBuilder;

  @override
  ConsumerState<PaginatedTaskList> createState() => _PaginatedTaskListState();
}

class _PaginatedTaskListState extends ConsumerState<PaginatedTaskList> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 200.0; // 距离底部 200px 时触发加载

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 当接近底部时，触发加载更多
    if (maxScroll - currentScroll < _loadMoreThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty && !widget.isLoading) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: widget.tasks.length + (widget.hasMore || widget.isLoading ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // 如果是最后一个项目，且正在加载或还有更多，显示加载指示器
        if (index >= widget.tasks.length) {
          if (widget.isLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (widget.hasMore) {
            // 理论上不应该到这里，但为了安全起见
            return const SizedBox.shrink();
          } else {
            return const SizedBox.shrink();
          }
        }

        final task = widget.tasks[index];
        return widget.itemBuilder(context, task, index);
      },
    );
  }
}

