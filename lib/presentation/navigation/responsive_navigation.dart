import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/task_section_utils.dart';
import '../../generated/l10n/app_localizations.dart';
import '../tasks/quick_tasks/quick_add_sheet.dart';
import 'drawer_menu.dart';
import 'navigation_bar.dart';
import 'navigation_destinations.dart';

/// 响应式导航组件
/// 根据屏幕方向自动切换导航方式：
/// - 横屏：显示 DrawerMenu
/// - 竖屏：显示 AppNavigationBar
class ResponsiveNavigation extends ConsumerStatefulWidget {
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
  ConsumerState<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends ConsumerState<ResponsiveNavigation> {
  bool _isLandscape = false;
  DrawerDisplayMode _currentDrawerMode = DrawerDisplayMode.hidden;
  final GlobalKey _navBarKey = GlobalKey();
  double? _navBarWidth;
  bool _fabHovered = false;

  @override
  void initState() {
    super.initState();
    // 不在 initState 中调用 _checkOrientation，因为此时 context 还没有完全初始化
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkOrientation();
    // 在布局完成后获取 NavigationBar 的实际宽度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavBarWidth();
    });
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

  /// 更新 NavigationBar 宽度
  void _updateNavBarWidth() {
    if (_navBarKey.currentContext != null && mounted) {
      final RenderBox? navBarBox =
          _navBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (navBarBox != null) {
        final newWidth = navBarBox.size.width;
        if (_navBarWidth != newWidth) {
          setState(() {
            _navBarWidth = newWidth;
          });
        }
      }
    }
  }

  void _setFabHovered(bool hovered) {
    if (_fabHovered != hovered) {
      setState(() {
        _fabHovered = hovered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 在 build 方法中也尝试更新 NavigationBar 宽度，以响应窗口大小变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavBarWidth();
    });
    
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
                  selectedIndex: widget.selectedIndex, // 使用正确的选中索引
                  onDestinationSelected: (destination) {
                    // 处理侧边栏导航，更新状态并跳转
                    widget.onDestinationSelected(NavigationDestinations.values.indexOf(destination));
                    context.go(destination.route);
                  },
                ),
              ),
              Expanded(child: widget.child),
            ],
          );
        } else {
          // 使用 Stack 将 NavigationBar 和 FAB 组合
          // FAB 叠加在 NavigationBar 中间按钮位置，保持其独立的外观
          return Scaffold(
            body: widget.child,
            bottomNavigationBar: Stack(
              clipBehavior: Clip.none,
              children: [
                // NavigationBar 包含 5 个目标，其中中间（索引 2）是 FAB 的占位
                AppNavigationBar(
                  key: _navBarKey,
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: widget.onDestinationSelected,
                ),
                // FAB 叠加在中间按钮位置
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final navBarWidth = _navBarWidth ?? screenWidth;

                      const double fabDiameter = 48.0; // FAB 直径（缩小后的尺寸）
                      const int fabSlotIndex = 2; // FAB 在第三个槽位（索引 2）
                      const int totalSlots = 5; // 总共 5 个槽位
                      final double slotWidth = navBarWidth / totalSlots;

                      // 计算 FAB 的水平位置（中间槽位的中心）
                      final double fabX =
                          slotWidth * fabSlotIndex + slotWidth / 2 - fabDiameter / 2;

                      // FAB 在导航栏中垂直居中（导航栏高度为 50dp）
                      // FAB 直径 48dp，所以顶部应该在 (50 - 48) / 2 = 1dp 的位置
                      const double fabY = 1.0;

                      const double fabPadding = 3; // 增加 padding，让按钮视觉上更轻盈
                      final colorScheme = Theme.of(context).colorScheme;

                      return Stack(
                        children: [
                          Positioned(
                            left: fabX,
                            top: fabY,
                            child: SizedBox(
                              width: fabDiameter,
                              height: fabDiameter,
                              child: MouseRegion(
                                onEnter: (_) => _setFabHovered(true),
                                onExit: (_) => _setFabHovered(false),
                                cursor: SystemMouseCursors.click,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: _fabHovered ? 12 : 6,
                                  ),
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, elevation, _) {
                                    final baseShadow =
                                        colorScheme.primary.withValues(alpha: 0.35);
                                    final hoverShadow =
                                        colorScheme.primary.withValues(alpha: 0.55);
                                    final t =
                                        ((elevation - 6) / 6).clamp(0.0, 1.0);
                                    final shadowColor =
                                        Color.lerp(baseShadow, hoverShadow, t)!;

                                    return Padding(
                                      padding: const EdgeInsets.all(fabPadding),
                                      child: Material(
                                        color: colorScheme.primary,
                                        shape: const CircleBorder(),
                                        elevation: elevation,
                                        shadowColor: shadowColor,
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () =>
                                              _showCreateTaskDialog(context),
                                          customBorder: const CircleBorder(),
                                          child: SizedBox.expand(
                                            child: Center(
                                              child: Icon(
                                                Icons.add,
                                                color: colorScheme.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// 显示创建任务弹窗
  void _showCreateTaskDialog(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final maxHeight = isLandscape 
        ? mediaQuery.size.height * 0.5  // 横屏时限制最大高度为屏幕高度的 50%
        : double.infinity;  // 竖屏时自适应内容高度

    // 使用 QuickAddSheet（不传 section，让用户选择日期）
    showModalBottomSheet<QuickAddResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: Container(
          width: double.infinity,
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
              // QuickAddSheet（不传 section）
              const QuickAddSheet(),
              // 底部安全区域
              SizedBox(height: mediaQuery.viewPadding.bottom + 20),
            ],
          ),
        ),
      ),
    ).then((result) {
      if (result == null || !context.mounted) return;
      _handleQuickAddResult(context, result);
    });
  }

  /// 处理快速添加任务的结果
  Future<void> _handleQuickAddResult(BuildContext context, QuickAddResult result) async {
    final taskService = await ref.read(taskServiceProvider.future);
    final l10n = AppLocalizations.of(context);

    try {
      if (result.dueDate == null) {
        // 未选择日期：放入收集箱（status 自动为 inbox）
        await taskService.captureInboxTask(title: result.title);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.inboxAddedToast)),
        );
      } else {
        // 选择日期：创建任务并规划到对应 section（status 自动为 pending）
        final newTask = await taskService.captureInboxTask(title: result.title);
        final section = TaskSectionUtils.getSectionForDate(result.dueDate!);
        await taskService.planTask(
          taskId: newTask.id,
          dueDateLocal: result.dueDate!,
          section: section,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.taskListAddedToast)),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to create task: $error\n$stackTrace');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.inboxAddError}: $error')),
      );
    }
  }
}