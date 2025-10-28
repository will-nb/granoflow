import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../core/providers/inbox_drag_provider.dart';
import '../common/drag/standard_draggable.dart';

/// Inbox页面拖拽处理组件
/// 
/// 使用 StandardDraggable 实现拖拽功能，只在任务闭合时启用
class InboxDraggable extends ConsumerWidget {
  const InboxDraggable({
    super.key,
    required this.task,
    required this.enabled,
    required this.child,
  });

  final Task task;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragNotifier = ref.read(inboxDragProvider.notifier);

    return StandardDraggable<Task>(
      data: task,
      enabled: enabled,
      onDragStarted: () => dragNotifier.startDrag(task),
      onDragEnd: () => dragNotifier.endDrag(),
      child: child,
    );
  }
}
