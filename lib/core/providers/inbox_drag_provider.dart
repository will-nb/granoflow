import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';

/// Inbox 拖拽目标类型
enum InboxDragTargetType { between, first, last }

/// Inbox 拖拽状态
class InboxDragState {
  const InboxDragState({
    this.draggedTask,
    this.hoverTarget,
    this.hoverTargetId,
    this.hoveredInsertionIndex,
    this.hoveredTaskId,
  });

  final Task? draggedTask;
  final InboxDragTargetType? hoverTarget;
  final int? hoverTargetId;
  // 统一拖拽系统：当前悬停的插入位置索引
  final int? hoveredInsertionIndex;
  // 统一拖拽系统：当前悬停的任务 ID
  final int? hoveredTaskId;

  bool get isDragging => draggedTask != null;

  InboxDragState copyWith({
    Task? draggedTask,
    InboxDragTargetType? hoverTarget,
    int? hoverTargetId,
    int? hoveredInsertionIndex,
    int? hoveredTaskId,
  }) {
    return InboxDragState(
      draggedTask: draggedTask ?? this.draggedTask,
      hoverTarget: hoverTarget ?? this.hoverTarget,
      hoverTargetId: hoverTargetId ?? this.hoverTargetId,
      hoveredInsertionIndex: hoveredInsertionIndex ?? this.hoveredInsertionIndex,
      hoveredTaskId: hoveredTaskId ?? this.hoveredTaskId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InboxDragState &&
        other.draggedTask == draggedTask &&
        other.hoverTarget == hoverTarget &&
        other.hoverTargetId == hoverTargetId &&
        other.hoveredInsertionIndex == hoveredInsertionIndex &&
        other.hoveredTaskId == hoveredTaskId;
  }

  @override
  int get hashCode {
    return draggedTask.hashCode ^
        hoverTarget.hashCode ^
        hoverTargetId.hashCode ^
        hoveredInsertionIndex.hashCode ^
        hoveredTaskId.hashCode;
  }
}

/// Inbox 拖拽状态管理
class InboxDragNotifier extends StateNotifier<InboxDragState> {
  InboxDragNotifier() : super(const InboxDragState());

  void startDrag(Task task) {
    state = InboxDragState(draggedTask: task);
  }

  void endDrag() {
    state = const InboxDragState();
  }

  void updateHoverTarget(InboxDragTargetType? type, {int? targetId}) {
    state = state.copyWith(hoverTarget: type, hoverTargetId: targetId);
  }

  /// 统一拖拽系统：更新插入位置悬停状态
  void updateInsertionHover(int? insertionIndex) {
    state = state.copyWith(
      hoveredInsertionIndex: insertionIndex,
      hoveredTaskId: null, // 清除任务表面悬停
    );
  }

  /// 统一拖拽系统：更新任务表面悬停状态
  void updateTaskSurfaceHover(int? taskId) {
    state = state.copyWith(
      hoveredTaskId: taskId,
      hoveredInsertionIndex: null, // 清除插入位置悬停
    );
  }

  /// 统一拖拽系统：清除所有悬停状态
  void clearHover() {
    // 即使已经是清除状态，也要触发更新，确保 UI 能正确还原
    if (state.hoveredInsertionIndex == null && state.hoveredTaskId == null) {
      // 如果已经是清除状态，不需要重复更新
      return;
    }
    state = state.copyWith(
      hoveredInsertionIndex: null,
      hoveredTaskId: null,
    );
  }
}

/// Inbox 拖拽状态 Provider
final inboxDragProvider = StateNotifierProvider<InboxDragNotifier, InboxDragState>((ref) {
  return InboxDragNotifier();
});
