import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';
import '../../widgets/swipe_action_type.dart';
import '../../widgets/task_tile_content.dart';

class TaskLeafTile extends ConsumerWidget {
  const TaskLeafTile({
    super.key,
    required this.task,
    required this.depth,
  });

  final Task task;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indentation = depth * 16.0;
    
    // 根据深度选择配置：depth > 0 的子任务使用删除，否则使用归档
    final config = depth > 0
        ? SwipeConfigs.tasksSubtaskConfig
        : SwipeConfigs.tasksConfig;

    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: DismissibleTaskTile(
        task: task,
        config: config,
        direction: DismissDirection.horizontal,
        onLeftAction: (task) => SwipeActionHandler.handleAction(
          context,
          ref,
          SwipeActionType.complete,
          task,
        ),
        onRightAction: (task) => SwipeActionHandler.handleAction(
          context,
          ref,
          config.rightAction,
          task,
        ),
        child: TaskTileContent(task: task),
      ),
    );
  }
}

