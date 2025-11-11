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
    // 使用SizedBox限制高度，符合2025年现代设计趋势（48-50dp）
    // iOS标准约为49px，Android标准约为56px，但现代设计更倾向于更紧凑的48-50dp
    return SizedBox(
      height: 50.0, // 设置为50dp，更符合现代设计趋势
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations ?? _getDefaultDestinations(context),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, // 始终隐藏标签
      ),
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
        label: '', // 去掉所有按钮文字
        tooltip: isFabDestination ? '' : destination.label(context), // 使用 tooltip 显示文字（悬停时）
        enabled: !isFabDestination,
      );
    }).toList();
  }
}