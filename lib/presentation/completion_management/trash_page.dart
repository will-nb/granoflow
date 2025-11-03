import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import '../widgets/task_filter_collapsible.dart';
import 'widgets/trashed_task_tile.dart';

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  final ScrollController _scrollController = ScrollController();
  static const double _loadMoreThreshold = 200.0;
  bool _hasLoadedInitial = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 加载初始数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[TrashPage] initState: Loading initial data');
      ref.read(trashedTasksPaginationProvider.notifier).loadInitial();
      _hasLoadedInitial = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当页面变为可见时，如果已经初始化过，则刷新数据
    if (_hasLoadedInitial && mounted) {
      debugPrint('[TrashPage] didChangeDependencies: Refreshing data');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(trashedTasksPaginationProvider.notifier).loadInitial();
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
    final paginationState = ref.read(trashedTasksPaginationProvider);
    if (!paginationState.hasMore || paginationState.isLoading) return;

    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // 当接近底部时，触发加载更多
    if (maxScroll - currentScroll < _loadMoreThreshold) {
      debugPrint('[TrashPage] _onScroll: Triggering loadMore');
      ref.read(trashedTasksPaginationProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paginationState = ref.watch(trashedTasksPaginationProvider);

    // 监听筛选条件变化，重置分页（必须在build方法中使用ref.listen）
    ref.listen<TaskFilterState>(trashedTasksFilterProvider, (previous, next) {
      if (previous != null && previous != next && _hasLoadedInitial) {
        // 筛选条件变化，重置分页
        debugPrint('[TrashPage] Filter changed, reloading data');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(trashedTasksPaginationProvider.notifier).loadInitial();
          }
        });
  }
    });

    debugPrint(
      '[TrashPage] build: tasks=${paginationState.tasks.length}, isLoading=${paginationState.isLoading}, hasMore=${paginationState.hasMore}, totalCount=${paginationState.totalCount}',
    );

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.navTrashTitle,
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
                filterProvider: trashedTasksFilterProvider,
              ),
            ),
          ),
          if (paginationState.tasks.isEmpty && !paginationState.isLoading)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
      child: Text(
                    l10n.trashEmptyMessage,
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
                      children: [
                        ...paginationState.tasks.asMap().entries.map((entry) {
                          final index = entry.key;
                          final task = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < paginationState.tasks.length - 1 ? 12 : 0,
                            ),
                            child: TrashedTaskTile(task: task),
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
