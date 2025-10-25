import 'package:flutter/material.dart';
import 'navigation_destinations.dart';
import '../widgets/create_task_dialog.dart';

/// 抽屉菜单显示模式
enum DrawerDisplayMode {
  /// 隐藏模式 - 宽度为0
  hidden,
  /// 仅图标模式 - 宽度为80，只显示图标
  iconOnly,
  /// 完整模式 - 宽度为280，显示图标和文字
  full,
}

/// 抽屉菜单组件
/// 支持三种显示模式：隐藏、仅图标、完整
class DrawerMenu extends StatelessWidget {
  const DrawerMenu({
    super.key,
    required this.displayMode,
    required this.selectedIndex,
    this.onDestinationSelected,
    this.onClose,
  });

  /// 显示模式
  final DrawerDisplayMode displayMode;
  
  /// 当前选中的索引
  final int selectedIndex;
  
  /// 目标选择回调
  final ValueChanged<NavigationDestinations>? onDestinationSelected;
  
  /// 关闭回调
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        width: _getDrawerWidth(),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            if (displayMode == DrawerDisplayMode.full)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Center(
                  child: Text(
                    'GranoFlow',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: displayMode == DrawerDisplayMode.iconOnly
                  ? ListView(
                      children: NavigationDestinations.values.asMap().entries.map((entry) {
                        final index = entry.key;
                        final destination = entry.value;
                        final isSelected = index == selectedIndex;
                        
                        return InkWell(
                          onTap: () {
                            onDestinationSelected?.call(destination);
                            onClose?.call();
                          },
                          child: Container(
                            height: 56,
                            width: double.infinity,
                            child: Center(
                              child: Icon(
                                destination.icon,
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : ListView(
                      children: NavigationDestinations.values.asMap().entries.map((entry) {
                        final index = entry.key;
                        final destination = entry.value;
                        final isSelected = index == selectedIndex;
                        
                        return ListTile(
                          leading: Icon(
                            destination.icon,
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 24,
                          ),
                          title: Text(
                            destination.label(context),
                            style: TextStyle(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            onDestinationSelected?.call(destination);
                            onClose?.call();
                          },
                        );
                      }).toList(),
                    ),
            ),
            // 横屏模式下集成 FAB
            if (MediaQuery.of(context).orientation == Orientation.landscape)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: FloatingActionButton(
                      onPressed: () => _showCreateTaskDialog(context),
                      child: const Icon(Icons.add, size: 24),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 4, // 悬浮突出效果
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 根据显示模式获取抽屉宽度
  double _getDrawerWidth() {
    switch (displayMode) {
      case DrawerDisplayMode.hidden:
        return 0;
      case DrawerDisplayMode.iconOnly:
        return 80;
      case DrawerDisplayMode.full:
        return 280;
    }
  }

  /// 显示创建任务弹窗
  void _showCreateTaskDialog(BuildContext context) {
    // 横屏模式：从左往右滑出
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const CreateTaskDialog();
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
  }
}