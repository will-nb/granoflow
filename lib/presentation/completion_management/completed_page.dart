import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/task_filter_collapsible.dart';
import '../widgets/simplified_task_row.dart';
import '../widgets/dismissible_task_tile.dart';
import '../widgets/swipe_action_handler.dart';
import '../widgets/swipe_configs.dart';

class CompletedPage extends ConsumerStatefulWidget {
  const CompletedPage({super.key});

  @override
  ConsumerState<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends ConsumerState<CompletedPage> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 200.0;
  bool _hasLoadedInitial = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 加载初始数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[CompletedPage] initState: Loading initial data');
      ref.read(completedTasksPaginationProvider.notifier).loadInitial();
      _hasLoadedInitial = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面变为可见时，如果已经初始化过，则刷新数据
    if (_hasLoadedInitial && mounted) {
      debugPrint('[CompletedPage] didChangeDependencies: Refreshing data');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(completedTasksPaginationProvider.notifier).loadInitial();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final paginationState = ref.read(completedTasksPaginationProvider);
    if (!paginationState.hasMore || paginationState.isLoading) return;

    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 当接近底部时，触发加载更多
    if (maxScroll - currentScroll < _loadMoreThreshold) {
      debugPrint('[CompletedPage] _onScroll: Triggering loadMore');
      ref.read(completedTasksPaginationProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paginationState = ref.watch(completedTasksPaginationProvider);

    // 监听筛选条件变化，重置分页（必须在build方法中使用ref.listen）
    ref.listen<TaskFilterState>(completedTasksFilterProvider, (previous, next) {
      if (previous != null && previous != next && _hasLoadedInitial) {
        // 筛选条件变化，重置分页
        debugPrint('[CompletedPage] Filter changed, reloading data');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(completedTasksPaginationProvider.notifier).loadInitial();
          }
        });
      }
    });

    debugPrint(
      '[CompletedPage] build: tasks=${paginationState.tasks.length}, isLoading=${paginationState.isLoading}, hasMore=${paginationState.hasMore}, totalCount=${paginationState.totalCount}',
    );
    
    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.completedTabLabel,
      ),
      drawer: const MainDrawer(),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 筛选UI
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TaskFilterCollapsible(
                filterProvider: completedTasksFilterProvider,
                projectsProvider: projectsForCompletedArchivedFilterProvider,
              ),
            ),
          ),
          if (paginationState.tasks.isEmpty && !paginationState.isLoading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
      child: Text(
                    l10n.completedEmptyMessage,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
                ),
              ),
            )
          else if (paginationState.tasks.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...paginationState.tasks.map((task) {
                          return DismissibleTaskTile(
                            key: ValueKey('completed-${task.id}-${task.updatedAt.millisecondsSinceEpoch}'),
                            task: task,
                            config: SwipeConfigs.completedArchivedConfig,
                            onLeftAction: (task) {
                              SwipeActionHandler.handleAction(
                                context,
                                ref,
                                SwipeConfigs.completedArchivedConfig.leftAction,
                                task,
                              );
                            },
                            onRightAction: (task) {
                              SwipeActionHandler.handleAction(
                                context,
                                ref,
                                SwipeConfigs.completedArchivedConfig.rightAction,
                                task,
                              );
                            },
                            child: SimplifiedTaskRow(
                              key: ValueKey(task.id),
                              task: task,
                              verticalPadding: 12.0,
                            ),
                          );
                        }),
                        if (paginationState.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (paginationState.isLoading && paginationState.tasks.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }
}
