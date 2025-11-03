import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_spacing_tokens.dart';
import '../../data/models/task.dart';
import 'task_row_content.dart';
import '../common/drag/standard_draggable.dart';

/// 统一的任务卡片内容布局
///
/// 包含：
/// - 左侧拖拽指示器（drag_indicator 图标）
/// - 右侧任务内容（TaskRowContent，支持 inline 编辑）
///
/// 注意：DragTarget 功能已移到外层，由列表组件（如 InboxTaskList、TaskSectionTaskModeList）处理。
///
/// 用于 Inbox 和 Tasks 页面，确保视觉和交互的完全一致性。
///
/// 使用方式：
/// ```dart
/// TaskTileContent(task: myTask)
/// ```
class TaskTileContent extends ConsumerStatefulWidget {
  const TaskTileContent({
    super.key,
    required this.task,
    this.compact = false,
    this.leading,
    this.trailing,
    this.contentPadding,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.childWhenDraggingOpacity,
    this.taskLevel, // 任务的层级（level），用于判断是否是子任务
  });

  final Task task;
  final bool compact;
  final Widget? leading;
  final Widget? trailing; // 尾部内容（如展开/收缩按钮）
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onDragStarted;
  final void Function(DragUpdateDetails)? onDragUpdate;
  final VoidCallback? onDragEnd;
  final double? childWhenDraggingOpacity;
  /// 任务的层级（level），用于判断是否是子任务
  /// level > 1 表示是子任务，子任务不显示截止日期
  final int? taskLevel;

  @override
  ConsumerState<TaskTileContent> createState() => _TaskTileContentState();
}

class _TaskTileContentState extends ConsumerState<TaskTileContent> {
  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    final handle = widget.leading != null
        ? Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: widget.leading!,
          )
        : Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: Icon(
              Icons.drag_indicator,
              color: Colors.grey[400],
              size: 20,
            ),
          );

    // 从 theme 获取 spacing tokens（测试环境可能没有设置，使用默认值回退）
    final spacing = Theme.of(context).extension<AppSpacingTokens>();
    final defaultPadding = EdgeInsets.symmetric(
      horizontal: spacing?.taskTileHorizontalPadding ?? 16.0,
      vertical: spacing?.taskTileVerticalPadding ?? 8.0,
    );

    return Padding(
      padding: widget.contentPadding ?? defaultPadding,
      child: StandardDraggable<Task>(
        data: widget.task,
        handle: handle,
        onDragStarted: widget.onDragStarted,
        onDragUpdate: widget.onDragUpdate,
        onDragEnd: widget.onDragEnd,
        childWhenDraggingOpacity: widget.childWhenDraggingOpacity,
        child: TaskRowContent(
          task: widget.task,
          compact: widget.compact,
          trailing: widget.trailing,
          taskLevel: widget.taskLevel,
        ),
      ),
    );
  }
}
