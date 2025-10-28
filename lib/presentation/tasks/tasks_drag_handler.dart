import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../core/providers/tasks_drag_provider.dart';

/// Tasks页面拖拽处理组件
/// 
/// 使用LongPressDraggable实现拖拽功能，只在任务闭合时启用
class TasksPageDragHandler extends ConsumerWidget {
  const TasksPageDragHandler({
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
    final dragNotifier = ref.read(tasksDragProvider.notifier);

    if (!enabled) {
      return child;
    }

    return LongPressDraggable<Task>(
      data: task,
          onDragStarted: () {
            dragNotifier.startDrag(task);
          },
          onDragEnd: (_) {
            dragNotifier.endDrag();
          },
      feedback: Transform.rotate(
        angle: 0.26, // 15度倾斜
        child: Transform.scale(
          scale: 1.05, // 放大1.05倍
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(8),
            shadowColor: Colors.black.withValues(alpha: 0.3),
            child: Opacity(
              opacity: 0.5,
              child: SizedBox(
                width: 300,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.dueAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDueDate(task.dueAt!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: child,
      ),
      child: child,
    );
  }

  String _formatDueDate(DateTime dueAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(dueAt.year, dueAt.month, dueAt.day);
    
    if (dueDate == today) {
      return '今天 ${dueAt.hour.toString().padLeft(2, '0')}:${dueAt.minute.toString().padLeft(2, '0')}';
    } else if (dueDate == today.add(const Duration(days: 1))) {
      return '明天 ${dueAt.hour.toString().padLeft(2, '0')}:${dueAt.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dueAt.month}/${dueAt.day} ${dueAt.hour.toString().padLeft(2, '0')}:${dueAt.minute.toString().padLeft(2, '0')}';
    }
  }
}
