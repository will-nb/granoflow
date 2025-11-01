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
    this.contentPadding,
    this.trailing,
    this.onDragStarted,
    this.onDragEnd,
  });

  final Task task;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? trailing; // 尾部内容（如展开/收缩按钮）
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

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
        leading: const Icon(Icons.drag_indicator_rounded, size: 20),
        trailing: trailing,
        contentPadding: contentPadding,
        onDragStarted: onDragStarted,
        onDragEnd: onDragEnd,
      ),
    );
    return tileContent;
  }
}

