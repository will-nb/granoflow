import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/service_providers.dart';
import '../../core/utils/task_section_utils.dart';
import '../../generated/l10n/app_localizations.dart';
import '../tasks/quick_tasks/quick_add_sheet.dart';
import '../widgets/app_logo.dart';
import 'navigation_destinations.dart';

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
class DrawerMenu extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
                  child: AppLogo(
                    size: 40.0,
                    showText: true,
                    variant: AppLogoVariant.onPrimary,
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
                      onPressed: () => _showCreateTaskDialog(context, ref),
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
  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    // 使用底部弹窗（与 ResponsiveNavigation 保持一致）
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final maxHeight = isLandscape 
        ? mediaQuery.size.height * 0.5
        : double.infinity;

    // 使用 QuickAddSheet（不传 section，让用户选择日期）
    showModalBottomSheet<QuickAddResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
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
      _handleQuickAddResult(context, ref, result);
    });
  }

  /// 处理快速添加任务的结果
  Future<void> _handleQuickAddResult(
    BuildContext context,
    WidgetRef ref,
    QuickAddResult result,
  ) async {
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