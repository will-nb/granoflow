import 'package:flutter/material.dart';
import 'navigation_destinations.dart';

/// 应用导航栏组件
/// 使用 BottomAppBar 实现底部导航栏，中间位置为 FAB 预留缺口
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  /// 当前选中的索引
  final int selectedIndex;
  
  /// 目标选择回调
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    // 获取所有导航目标，排除中间的 add（FAB）
    final destinations = NavigationDestinations.values
        .where((d) => d != NavigationDestinations.add)
        .toList();

    final colorScheme = Theme.of(context).colorScheme;
    // 浅色模式使用 tertiaryContainer（天际白）提供更好的对比度，深色模式使用 surface
    final backgroundColor = colorScheme.brightness == Brightness.light
        ? colorScheme.tertiaryContainer
        : colorScheme.surface;

    return BottomAppBar(
      height: 50.0, // 保持高度 50dp
      color: backgroundColor, // 根据主题设置背景色
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0, // FAB 与导航栏的间距，调整以确保 FAB 与其他图标底部对齐
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home (索引 0)
          _buildIconButton(
            context: context,
            destination: destinations[0],
            index: 0,
            isSelected: selectedIndex == 0,
          ),
          // Tasks (索引 1)
          _buildIconButton(
            context: context,
            destination: destinations[1],
            index: 1,
            isSelected: selectedIndex == 1,
          ),
          // FAB 占位空间（索引 2 是 add，由 FAB 占据）
          const SizedBox(width: 48),
          // Achievements (索引 3)
          _buildIconButton(
            context: context,
            destination: destinations[2],
            index: 3,
            isSelected: selectedIndex == 3,
          ),
          // Settings (索引 4)
          _buildIconButton(
            context: context,
            destination: destinations[3],
            index: 4,
            isSelected: selectedIndex == 4,
          ),
        ],
      ),
    );
  }

  /// 构建图标按钮
  Widget _buildIconButton({
    required BuildContext context,
    required NavigationDestinations destination,
    required int index,
    required bool isSelected,
  }) {
    return IconButton(
      icon: Icon(
        isSelected ? destination.selectedIcon : destination.icon,
        size: 24.0, // 明确指定图标大小
      ),
      tooltip: destination.label(context),
      onPressed: () => onDestinationSelected(index),
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant,
      constraints: const BoxConstraints(
        minWidth: 40.0, // 减小最小宽度，使 hover 背景更紧凑
        minHeight: 40.0, // 减小最小高度，使 hover 背景更紧凑
      ),
      padding: EdgeInsets.zero, // 移除默认 padding
      visualDensity: VisualDensity.compact, // 紧凑模式
    );
  }
}