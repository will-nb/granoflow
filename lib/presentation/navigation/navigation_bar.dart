import 'package:flutter/material.dart';
import 'navigation_destinations.dart';

/// 应用导航栏组件
/// 用于底部导航栏，显示所有导航目标
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.destinations,
  });

  /// 当前选中的索引
  final int selectedIndex;
  
  /// 目标选择回调
  final ValueChanged<int> onDestinationSelected;
  
  /// 自定义目标列表，如果为null则使用默认目标
  final List<NavigationDestination>? destinations;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations ?? _getDefaultDestinations(context),
    );
  }

  /// 获取默认的导航目标列表
  /// 包含 5 个目标：[Home, Tasks, Add (FAB), Achievements, Settings]
  List<NavigationDestination> _getDefaultDestinations(BuildContext context) {
    return NavigationDestinations.values.map((destination) {
      final isFabDestination = destination == NavigationDestinations.add;

      return NavigationDestination(
        icon: isFabDestination
            ? const SizedBox.shrink()
            : Icon(destination.icon),
        selectedIcon: isFabDestination
            ? const SizedBox.shrink()
            : Icon(destination.selectedIcon),
        label: destination.label(context),
        tooltip: isFabDestination ? '' : null,
        enabled: !isFabDestination,
      );
    }).toList();
  }
}