import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';
import '../../widgets/task_tile_content.dart';
import '../inbox_draggable.dart';

class InboxTaskTile extends ConsumerWidget {
  const InboxTaskTile({
    super.key,
    required this.task,
    this.leading,
  });

  final Task task;
  final Widget? leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = SwipeConfigs.inboxConfig;
    final tileContent = DismissibleTaskTile(
      key: ValueKey('inbox-${task.id}-${task.updatedAt.millisecondsSinceEpoch}'),
      task: task,
      config: config,
      onLeftAction: (task) {
        SwipeActionHandler.handleAction(
          context,
          ref,
          config.leftAction,
          task,
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
      child: TaskTileContent(task: task, leading: leading),
    );
    
    // 添加拖拽支持，使任务可以被拖拽到其他任务上成为子任务
    return InboxDraggable(
      task: task,
      enabled: true,
      child: tileContent,
    );
  }
}

