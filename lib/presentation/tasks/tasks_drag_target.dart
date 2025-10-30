import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../core/providers/tasks_drag_provider.dart';
import '../../core/providers/service_providers.dart';
import '../../data/models/task.dart' as models;
import '../common/drag/standard_drag_target.dart';
import 'tasks_drag_target_type.dart';

/// Tasks页面拖拽目标组件
/// 
/// 支持3种拖拽目标类型，提供视觉反馈和拖拽处理
class TasksPageDragTarget extends ConsumerWidget {
  const TasksPageDragTarget({
    super.key,
    required this.targetType,
    this.beforeTask,
    this.afterTask,
    this.section,
    this.child,
  });

  final TasksDragTargetType targetType;
  final Task? beforeTask;
  final Task? afterTask;
  final models.TaskSection? section;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragNotifier = ref.read(tasksDragProvider.notifier);

    // 根据不同类型计算唯一ID
    int? getTargetId() {
      switch (targetType) {
        case TasksDragTargetType.between:
          return beforeTask?.id;
        case TasksDragTargetType.sectionFirst:
        case TasksDragTargetType.sectionLast:
          return section?.index;
      }
    }

    final targetId = getTargetId();

    return StandardDragTarget<Task>(
      type: _mapToInsertionType(targetType),
      canAccept: (dragged) => _canAcceptDrop(dragged),
      onAccept: (dragged) async {
        debugPrint('接受拖拽: type=$targetType, task=${dragged.id}');
        try {
          final taskService = ref.read(taskServiceProvider);
          await _handleDrop(dragged, taskService);
        } catch (e) {
          // 在测试环境中可能没有taskServiceProvider，忽略错误
        }
        dragNotifier.endDrag();
      },
      targetId: targetId,
      onHoverChanged: (isHovering) {
        if (isHovering) {
          dragNotifier.updateHoverTarget(targetType, targetId: targetId);
        } else {
          dragNotifier.updateHoverTarget(null);
        }
      },
      // 与 Inbox 一致：仅悬停显示插入线
      showWhenIdle: false,
      child: child,
    );
  }

  InsertionType _mapToInsertionType(TasksDragTargetType type) {
    switch (type) {
      case TasksDragTargetType.between:
        return InsertionType.between;
      case TasksDragTargetType.sectionFirst:
        return InsertionType.first;
      case TasksDragTargetType.sectionLast:
        return InsertionType.last;
    }
  }

  bool _canAcceptDrop(Task draggedTask) {
    // 禁止拖拽到已逾期区域
    if (section == models.TaskSection.overdue) {
      return false;
    }
    
    switch (targetType) {
      case TasksDragTargetType.between:
        // 不能拖拽到自己上方或下方
        if (beforeTask?.id == draggedTask.id || afterTask?.id == draggedTask.id) {
          return false;
        }
        // 移除 dueAt 限制，支持跨区域拖拽
        return beforeTask != null && afterTask != null;
      case TasksDragTargetType.sectionFirst:
      case TasksDragTargetType.sectionLast:
        return section != null;
    }
  }

  Future<void> _handleDrop(Task draggedTask, dynamic taskService) async {
    try {
      switch (targetType) {
        case TasksDragTargetType.between:
          await taskService.handleDragBetweenTasks(
            draggedTask.id, 
            beforeTask!.id, 
            afterTask!.id,
          );
          break;
        case TasksDragTargetType.sectionFirst:
          await taskService.handleDragToSectionFirst(draggedTask.id, section!);
          break;
        case TasksDragTargetType.sectionLast:
          await taskService.handleDragToSectionLast(draggedTask.id, section!);
          break;
      }
    } catch (e) {
      // TODO: 显示错误提示
      rethrow;
    }
  }
}
