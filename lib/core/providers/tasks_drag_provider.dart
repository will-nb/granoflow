import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../presentation/tasks/tasks_drag_target_type.dart';

/// Tasks页面拖拽状态
class TasksDragState {
  final Task? draggedTask;
  final TasksDragTargetType? hoverTarget;
  final int? hoverTargetId; // 用于区分同类型的不同目标
  final bool isDragging;
  
  const TasksDragState({
    this.draggedTask,
    this.hoverTarget,
    this.hoverTargetId,
    this.isDragging = false,
  });

  TasksDragState copyWith({
    Task? draggedTask,
    TasksDragTargetType? hoverTarget,
    int? hoverTargetId,
    bool? isDragging,
  }) {
    return TasksDragState(
      draggedTask: draggedTask ?? this.draggedTask,
      hoverTarget: hoverTarget ?? this.hoverTarget,
      hoverTargetId: hoverTargetId ?? this.hoverTargetId,
      isDragging: isDragging ?? this.isDragging,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TasksDragState &&
        other.draggedTask == draggedTask &&
        other.hoverTarget == hoverTarget &&
        other.hoverTargetId == hoverTargetId &&
        other.isDragging == isDragging;
  }

  @override
  int get hashCode {
    return draggedTask.hashCode ^
        hoverTarget.hashCode ^
        hoverTargetId.hashCode ^
        isDragging.hashCode;
  }
}

/// Tasks页面拖拽状态管理器
class TasksDragNotifier extends StateNotifier<TasksDragState> {
  TasksDragNotifier() : super(const TasksDragState());
  
  /// 开始拖拽
  void startDrag(Task task) {
    state = state.copyWith(
      draggedTask: task,
      isDragging: true,
    );
  }
  
  /// 更新悬停目标
  void updateHoverTarget(TasksDragTargetType? targetType, {int? targetId}) {
    state = state.copyWith(
      hoverTarget: targetType,
      hoverTargetId: targetId,
    );
  }
  
  /// 结束拖拽
  void endDrag() {
    state = const TasksDragState();
  }
}

/// Tasks页面拖拽状态Provider
final tasksDragProvider = StateNotifierProvider<TasksDragNotifier, TasksDragState>(
  (ref) => TasksDragNotifier(),
);
