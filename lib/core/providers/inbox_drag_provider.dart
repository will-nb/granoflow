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
  });

  final Task? draggedTask;
  final InboxDragTargetType? hoverTarget;
  final int? hoverTargetId;

  bool get isDragging => draggedTask != null;

  InboxDragState copyWith({
    Task? draggedTask,
    InboxDragTargetType? hoverTarget,
    int? hoverTargetId,
  }) {
    return InboxDragState(
      draggedTask: draggedTask ?? this.draggedTask,
      hoverTarget: hoverTarget ?? this.hoverTarget,
      hoverTargetId: hoverTargetId ?? this.hoverTargetId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InboxDragState &&
        other.draggedTask == draggedTask &&
        other.hoverTarget == hoverTarget &&
        other.hoverTargetId == hoverTargetId;
  }

  @override
  int get hashCode {
    return draggedTask.hashCode ^ hoverTarget.hashCode ^ hoverTargetId.hashCode;
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
}

/// Inbox 拖拽状态 Provider
final inboxDragProvider = StateNotifierProvider<InboxDragNotifier, InboxDragState>((ref) {
  return InboxDragNotifier();
});
