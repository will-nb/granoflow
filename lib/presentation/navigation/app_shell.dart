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
        // 如果点击的是 FAB 按钮（索引 2），不更新导航状态也不跳转
        // FAB 的点击事件由 ResponsiveNavigation 中的 Stack 处理
        if (index == NavigationDestinations.values.indexOf(NavigationDestinations.add)) {
          // FAB 的点击事件已经在 ResponsiveNavigation 中处理
          // 这里不需要做任何操作，因为 FAB 是叠加在 NavigationBar 上的独立组件
          return;
        }
        
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