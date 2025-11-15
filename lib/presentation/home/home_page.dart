import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/home_statistics_providers.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import 'widgets/home_statistics_widget.dart';
import 'widgets/task_search_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _hasLoadedInitial = false;
  String? _lastLocation;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    // 触发种子导入，但不监听状态变化（避免无限重建）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🟢 HomePage: initState: triggering seed import...');
      try {
        ref.read(seedInitializerProvider);
        debugPrint('🟢 HomePage: seedInitializerProvider read successfully');
      } catch (error, stackTrace) {
        debugPrint('🔴 HomePage: ERROR - Failed to read seedInitializerProvider: $error');
        debugPrint('🔴 HomePage: Stack trace: $stackTrace');
      }
      _hasLoadedInitial = true;
      // 初始化时刷新一次统计数据
      _refreshStatistics();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 检查路由是否变化，如果变化则刷新统计数据
    final route = ModalRoute.of(context);
    final isCurrentRoute = route?.isCurrent ?? false;
    
    if (_hasLoadedInitial && isCurrentRoute) {
      // 使用 GoRouter 获取当前路由路径
      final router = GoRouter.of(context);
      final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
      
      // 如果路由路径变化，说明进入了新页面
      if (currentLocation == '/' && currentLocation != _lastLocation) {
        _lastLocation = currentLocation;
        debugPrint('[HomePage] Route changed to: $currentLocation, refreshing statistics');
        _refreshStatistics();
      }
    }
  }

  void _refreshStatistics() {
    if (!mounted) return;
    
    // 防止频繁刷新：如果距离上次刷新不到 500ms，则跳过
    final now = DateTime.now();
    if (_lastRefreshTime != null && now.difference(_lastRefreshTime!).inMilliseconds < 500) {
      return;
    }
    _lastRefreshTime = now;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('[HomePage] Refreshing all statistics providers');
        ref.invalidate(todayStatisticsProvider);
        ref.invalidate(thisWeekStatisticsProvider);
        ref.invalidate(thisMonthStatisticsProvider);
        ref.invalidate(totalStatisticsProvider);
        ref.invalidate(thisMonthTopCompletedDateProvider);
        ref.invalidate(thisMonthTopFocusDateProvider);
        ref.invalidate(totalTopCompletedDateProvider);
        ref.invalidate(totalTopFocusDateProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allStatisticsAsync = ref.watch(allStatisticsProvider);
    
    // 在 build 方法中检查路由状态，确保每次进入首页时刷新数据
    if (_hasLoadedInitial) {
      final router = GoRouter.of(context);
      final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
      
      // 如果当前是首页且路由路径变化，刷新统计数据
      if (currentLocation == '/' && currentLocation != _lastLocation) {
        _lastLocation = currentLocation;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshStatistics();
          }
        });
      }
    }

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.homePageTitle,
      ),
      drawer: const MainDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final theme = Theme.of(context);
          final textTheme = theme.textTheme;
          final colorScheme = theme.colorScheme;
          
          // 根据主题亮度选择文字颜色
          final heroTextColor = theme.brightness == Brightness.light
              ? colorScheme.onSurface
              : Colors.white;

          final greeting = Text(
            l10n.homeGreeting,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: heroTextColor,
              letterSpacing: 0.3,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            textAlign: TextAlign.start,
          );

          final subtitle = Text(
            l10n.homeTagline,
            style: textTheme.bodyLarge?.copyWith(
              color: heroTextColor.withValues(alpha: 0.85),
              height: 1.4,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            textAlign: TextAlign.start,
          );

          // 根据主题亮度选择 Logo variant
          final logoVariant = theme.brightness == Brightness.light
              ? AppLogoVariant.primary
              : AppLogoVariant.onPrimary;

          // 将 Logo + 标题 + 标语打包为一个横向 heroBlock
          final heroBlock = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: isWide ? 80 : 64,
                height: isWide ? 80 : 64,
                child: AppLogo(
                  size: isWide ? 80 : 64,
                  showText: false,
                  variant: logoVariant,
                ),
              ),
              SizedBox(width: isWide ? 20 : 16),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    greeting,
                    const SizedBox(height: 8),
                    subtitle,
                  ],
                ),
              ),
            ],
          );

          // Hero + 搜索栏的组合
          final heroWithSearch = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              heroBlock,
              const SizedBox(height: 24),
              TaskSearchBar(
                onTap: () => context.go('/search'),
              ),
            ],
          );

          return allStatisticsAsync.when(
            data: (allStatistics) {
              // 判断是否为空数据
              final isEmpty = allStatistics.today.completedCount == 0 &&
                  allStatistics.today.focusMinutes == 0 &&
                  allStatistics.thisWeek.completedCount == 0 &&
                  allStatistics.thisWeek.focusMinutes == 0 &&
                  allStatistics.thisMonth.completedCount == 0 &&
                  allStatistics.thisMonth.focusMinutes == 0 &&
                  allStatistics.total.completedCount == 0 &&
                  allStatistics.total.focusMinutes == 0;

              if (isEmpty) {
                // 空状态：heroBlock + 搜索栏居中显示（上下左右都居中）
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: heroWithSearch,
                    ),
                  ),
                );
              }

              // 有数据时的布局
              if (isWide) {
                // 宽屏：左右两栏布局，heroBlock 垂直居中
                return Padding(
                  padding: EdgeInsets.only(
                    top: 24,
                    bottom: 16,
                    left: constraints.maxWidth >= 1200 ? 48 : 32,
                    right: constraints.maxWidth >= 1200 ? 48 : 32,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中
                    children: [
                      // 左侧栏：Hero + 搜索栏（垂直居中）
                      Flexible(
                        flex: constraints.maxWidth >= 1200 ? 35 : 30,
                        child: Center(
                          child: heroWithSearch,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 1200 ? 48 : 32,
                      ),
                      // 右侧栏：统计表
                      Flexible(
                        flex: constraints.maxWidth >= 1200 ? 50 : 40,
                        child: const HomeStatisticsWidget(),
                      ),
                    ],
                  ),
                );
              } else {
                // 窄屏：垂直布局
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(todayStatisticsProvider);
                    ref.invalidate(thisWeekStatisticsProvider);
                    ref.invalidate(thisMonthStatisticsProvider);
                    ref.invalidate(totalStatisticsProvider);
                    ref.invalidate(thisMonthTopCompletedDateProvider);
                    ref.invalidate(thisMonthTopFocusDateProvider);
                    ref.invalidate(totalTopCompletedDateProvider);
                    ref.invalidate(totalTopFocusDateProvider);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        heroBlock,
                        const SizedBox(height: 24),
                        TaskSearchBar(
                          onTap: () => context.go('/search'),
                        ),
                        const HomeStatisticsWidget(),
                      ],
                    ),
                  ),
                );
              }
            },
            loading: () {
              // 加载中时，显示居中布局（与空状态一致）
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: heroWithSearch,
                  ),
                ),
              );
            },
            error: (error, stack) {
              // 错误时，也显示居中布局
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        heroWithSearch,
                        const SizedBox(height: 24),
                        Text(
                          'Error: $error',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
