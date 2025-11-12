import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/simplified_task_row.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';
import '../utils/tree_flattening_utils.dart';

/// 任务层级列表组件（简化版）
///
/// 使用 SimplifiedTaskRow 显示任务，所有任务平铺显示
/// 移除层级结构和展开/收缩功能
/// 支持滑动操作：项目子任务使用 tasksSubtaskConfig（右滑完成，左滑删除）
class TaskHierarchyList extends ConsumerWidget {
  const TaskHierarchyList({super.key, required this.nodes});

  final List<FlattenedTaskNode> nodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (nodes.isEmpty) {
      return const SizedBox.shrink();
    }
    // 平铺显示所有任务，使用 SimplifiedTaskRow，包裹在 DismissibleTaskTile 中支持滑动
    // 项目子任务通常是 level > 1，使用 tasksSubtaskConfig
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes
          .map((node) {
            final task = node.task;
            final taskLevel = node.depth + 1; // depth 从 0 开始，level 从 1 开始
            
            return DismissibleTaskTile(
              key: ValueKey('hierarchy-${task.id}-${task.updatedAt.millisecondsSinceEpoch}'),
              task: task,
              config: SwipeConfigs.tasksSubtaskConfig,
              onLeftAction: (task) {
                SwipeActionHandler.handleAction(
                  context,
                  ref,
                  SwipeConfigs.tasksSubtaskConfig.leftAction,
                  task,
                  taskLevel: taskLevel,
                );
              },
              onRightAction: (task) {
                SwipeActionHandler.handleAction(
                  context,
                  ref,
                  SwipeConfigs.tasksSubtaskConfig.rightAction,
                  task,
                );
              },
              child: SimplifiedTaskRow(
                key: ValueKey(node.task.id),
                task: node.task,
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

