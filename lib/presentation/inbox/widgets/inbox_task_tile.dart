import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';
import '../../widgets/task_tile_content.dart';

class InboxTaskTile extends ConsumerWidget {
  const InboxTaskTile({
    super.key,
    required this.task,
    this.leading,
    this.contentPadding,
  });

  final Task task;
  final Widget? leading;
  final EdgeInsetsGeometry? contentPadding;

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
      child: TaskTileContent(
        task: task,
        leading: leading,
        contentPadding: contentPadding,
        dragPage: 'Inbox',
      ),
    );
    return tileContent;
  }
}

