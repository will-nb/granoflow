import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'drawer_menu.dart';
import 'navigation_bar.dart';
import '../widgets/create_task_dialog.dart';
import '../widgets/responsive_task_dialog.dart';

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
                  selectedIndex: 0, // 侧边栏有自己的选中状态
                  onDestinationSelected: (destination) {
                    // 处理侧边栏导航，直接跳转到对应路由
                    context.go(destination.route);
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
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showCreateTaskDialog(context),
              child: const Icon(Icons.add),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Reddit 风格圆角
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0, // 移除阴影，让它看起来像导航栏的一部分
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          );
        }
      },
    );
  }

  /// 显示创建任务弹窗
  void _showCreateTaskDialog(BuildContext context) {
    if (_isLandscape) {
      // 横屏模式：从左往右滑出（桌面风格）
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: const ResponsiveTaskDialog(),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      );
    } else {
      // 竖屏模式：底部弹窗（手机风格）
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildBottomSheet(context),
      );
    }
  }

  /// 构建底部弹窗，根据表单内容自动调整高度
  Widget _buildBottomSheet(BuildContext context) {
    return Container(
      width: double.infinity, // 100% 屏幕宽度，符合主流设计
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 表单内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: const CreateTaskDialog(),
          ),
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 20),
        ],
      ),
    );
  }
}