import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import 'responsive_navigation.dart';
import 'navigation_destinations.dart';

/// 应用壳组件
/// 管理统一DrawerMenu的三种显示状态
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    this.showEndDrawer = true,
  });

  /// 子组件
  final Widget child;
  
  /// 是否显示右侧抽屉
  final bool showEndDrawer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveNavigation(
      selectedIndex: ref.watch(navigationIndexProvider),
      onDestinationSelected: (index) {
        // 更新导航状态
        ref.read(navigationIndexProvider.notifier).state = index;
        
        // 执行实际的路由跳转
        final destination = NavigationDestinations.values[index];
        context.go(destination.route);
      },
      child: child,
    );
  }
}