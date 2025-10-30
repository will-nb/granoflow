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

    return Padding(
      padding: EdgeInsets.only(left: indentation),
      child: DismissibleTaskTile(
        task: task,
        config: SwipeConfigs.tasksConfig,
        direction: DismissDirection.horizontal,
        onLeftAction: (task) => SwipeActionHandler.handleAction(
          context,
          ref,
          SwipeActionType.postpone,
          task,
        ),
        onRightAction: (task) => SwipeActionHandler.handleAction(
          context,
          ref,
          SwipeActionType.archive,
          task,
        ),
        child: TaskTileContent(task: task),
      ),
    );
  }
}

