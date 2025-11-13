import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/task.dart';
import '../../widgets/simplified_task_row.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';

/// Inbox 页面的任务列表组件（简化版）
///
/// 使用 SimplifiedTaskRow 显示任务，只显示 inbox 状态的任务
/// 所有任务平铺显示，不显示层级结构
/// 支持滑动操作：右滑快速规划，左滑删除
class InboxTaskList extends ConsumerWidget {
  /// 创建 Inbox 任务列表组件
  ///
  /// [tasks] 是要显示的任务列表（应该只包含 inbox 状态的任务）
  const InboxTaskList({super.key, required this.tasks});

  /// 要显示的任务列表
  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 过滤掉非 inbox 状态的任务（确保只显示 inbox 状态）
    final inboxTasks = tasks
        .where((task) => task.status == TaskStatus.inbox)
        .toList();

    if (inboxTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // 使用 SimplifiedTaskRow 显示任务，平铺显示，包裹在 DismissibleTaskTile 中支持滑动
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: inboxTasks.map((task) {
        // 层级功能已移除，所有任务都使用相同的配置
        final config = SwipeConfigs.inboxConfig;
        
        // 层级功能已移除，所有任务都是 level 1
        final taskLevel = 1;

        return DismissibleTaskTile(
          key: ValueKey('inbox-${task.id}-${task.updatedAt.millisecondsSinceEpoch}'),
          task: task,
          config: config,
          onLeftAction: (task) {
            SwipeActionHandler.handleAction(
              context,
              ref,
              config.leftAction,
              task,
              taskLevel: taskLevel,
            );
          },
          onRightAction: (task) {
            SwipeActionHandler.handleAction(
              context,
              ref,
              config.rightAction,
              task,
            );
          },
          child: SimplifiedTaskRow(
            key: ValueKey(task.id),
            task: task,
            verticalPadding: 12.0,
          ),
        );
      }).toList(),
    );
  }
}
