import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/task.dart';
import '../../widgets/dismissible_task_tile.dart';
import '../../widgets/swipe_action_handler.dart';
import '../../widgets/swipe_configs.dart';
import '../../widgets/task_tile_content.dart';

class InboxTaskTile extends ConsumerStatefulWidget {
  const InboxTaskTile({
    super.key,
    required this.task,
    this.contentPadding,
    this.trailing,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.childWhenDraggingOpacity,
    this.taskLevel, // 任务的层级（level），用于判断是否是子任务
  });

  final Task task;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? trailing; // 尾部内容（如展开/收缩按钮）
  final VoidCallback? onDragStarted;
  final void Function(DragUpdateDetails)? onDragUpdate;
  final VoidCallback? onDragEnd;
  final double? childWhenDraggingOpacity;
  /// 任务的层级（level），用于判断是否是子任务
  /// level > 1 表示是子任务，子任务不显示截止日期
  final int? taskLevel;

  @override
  ConsumerState<InboxTaskTile> createState() => _InboxTaskTileState();
}

class _InboxTaskTileState extends ConsumerState<InboxTaskTile> {
  late final ValueNotifier<bool> _isEditingNotifier;

  @override
  void initState() {
    super.initState();
    _isEditingNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isEditingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根据任务 level 选择滑动配置
    // level > 1 表示是子任务，使用子任务专用配置（提升为独立任务 + 删除）
    // level = 1 或 null 表示是根任务，使用根任务配置（快速规划 + 删除）
    final config = (widget.taskLevel != null && widget.taskLevel! > 1)
        ? SwipeConfigs.inboxSubtaskConfig
        : SwipeConfigs.inboxConfig;
    
    final tileContent = DismissibleTaskTile(
      key: ValueKey('inbox-${widget.task.id}-${widget.task.updatedAt.millisecondsSinceEpoch}'),
      task: widget.task,
      config: config,
      isEditingNotifier: _isEditingNotifier,
      onLeftAction: (task) {
        SwipeActionHandler.handleAction(
          context,
          ref,
          config.leftAction,
          task,
          taskLevel: widget.taskLevel, // 传递 taskLevel，避免服务层重新计算
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
        task: widget.task,
        leading: const Icon(Icons.drag_indicator_rounded, size: 20),
        trailing: widget.trailing,
        contentPadding: widget.contentPadding,
        onDragStarted: widget.onDragStarted,
        onDragUpdate: widget.onDragUpdate,
        onDragEnd: widget.onDragEnd,
        childWhenDraggingOpacity: widget.childWhenDraggingOpacity,
        taskLevel: widget.taskLevel,
        isEditingNotifier: _isEditingNotifier,
      ),
    );
    return tileContent;
  }
}

