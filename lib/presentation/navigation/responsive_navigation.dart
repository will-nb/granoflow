import 'package:flutter/material.dart';
import 'drawer_menu.dart';
import 'navigation_bar.dart';
import 'navigation_destinations.dart';

/// 响应式导航组件
/// 根据屏幕方向自动切换导航方式：
/// - 横屏：显示 DrawerMenu
/// - 竖屏：显示 AppNavigationBar
class ResponsiveNavigation extends StatefulWidget {
  const ResponsiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
    this.drawerMode,
  });

  /// 当前选中的索引
  final int selectedIndex;
  
  /// 目标选择回调
  final ValueChanged<int> onDestinationSelected;
  
  /// 子组件
  final Widget child;
  
  /// 自定义抽屉模式，如果为null则根据屏幕方向自动决定
  final DrawerDisplayMode? drawerMode;

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  bool _isLandscape = false;
  DrawerDisplayMode _currentDrawerMode = DrawerDisplayMode.hidden;

  @override
  void initState() {
    super.initState();
    // 不在 initState 中调用 _checkOrientation，因为此时 context 还没有完全初始化
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkOrientation();
  }

  /// 检查屏幕方向
  void _checkOrientation() {
    final orientation = MediaQuery.of(context).orientation;
    setState(() {
      _isLandscape = orientation == Orientation.landscape;
      _currentDrawerMode = widget.drawerMode ?? 
        (_isLandscape ? DrawerDisplayMode.iconOnly : DrawerDisplayMode.hidden);
    });
  }

  /// 根据当前抽屉模式获取抽屉宽度
  double _getDrawerWidth() {
    switch (_currentDrawerMode) {
      case DrawerDisplayMode.hidden:
        return 0;
      case DrawerDisplayMode.iconOnly:
        return 80;
      case DrawerDisplayMode.full:
        return 280;
    }
  }

  /// 切换抽屉模式
  /// 在三种模式间循环：hidden -> iconOnly -> full -> hidden
  void toggleDrawerMode() {
    setState(() {
      switch (_currentDrawerMode) {
        case DrawerDisplayMode.hidden:
          _currentDrawerMode = DrawerDisplayMode.iconOnly;
          break;
        case DrawerDisplayMode.iconOnly:
          _currentDrawerMode = DrawerDisplayMode.full;
          break;
        case DrawerDisplayMode.full:
          _currentDrawerMode = DrawerDisplayMode.hidden;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_isLandscape) {
          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _getDrawerWidth(),
                child: DrawerMenu(
                  displayMode: _currentDrawerMode,
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: (destination) {
                    final index = NavigationDestinations.values.indexOf(destination);
                    widget.onDestinationSelected(index);
                  },
                ),
              ),
              Expanded(child: widget.child),
            ],
          );
        } else {
          return Scaffold(
            body: widget.child,
            bottomNavigationBar: AppNavigationBar(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
            ),
          );
        }
      },
    );
  }
}