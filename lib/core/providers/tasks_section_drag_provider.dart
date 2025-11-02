import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';

/// Tasks Section 拖拽状态
class TasksSectionDragState {
  const TasksSectionDragState({
    this.draggedTask,
    this.hoveredInsertionIndex,
    this.hoveredTaskId,
    this.dragStartPosition,
    this.currentDragPosition,
    this.horizontalOffset,
    this.verticalOffset,
    this.isDraggedTaskHiddenFromExpansion,
  });

  final Task? draggedTask;
  // 统一拖拽系统：当前悬停的插入位置索引
  final int? hoveredInsertionIndex;
  // 统一拖拽系统：当前悬停的任务 ID
  final int? hoveredTaskId;
  // 拖拽起始位置（全局坐标）
  final Offset? dragStartPosition;
  // 当前拖拽位置（全局坐标）
  final Offset? currentDragPosition;
  // 水平位移（dx = currentDragPosition.dx - dragStartPosition.dx）
  final double? horizontalOffset;
  // 垂直位移（dy = currentDragPosition.dy - dragStartPosition.dy）
  final double? verticalOffset;
  // 被拖拽的子任务是否已移出扩展区，应该在UI上隐藏
  final bool? isDraggedTaskHiddenFromExpansion;

  bool get isDragging => draggedTask != null;

  TasksSectionDragState copyWith({
    Task? draggedTask,
    int? hoveredInsertionIndex,
    int? hoveredTaskId,
    Offset? dragStartPosition,
    Offset? currentDragPosition,
    double? horizontalOffset,
    double? verticalOffset,
    bool? isDraggedTaskHiddenFromExpansion,
  }) {
    return TasksSectionDragState(
      draggedTask: draggedTask ?? this.draggedTask,
      hoveredInsertionIndex:
          hoveredInsertionIndex ?? this.hoveredInsertionIndex,
      hoveredTaskId: hoveredTaskId ?? this.hoveredTaskId,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      currentDragPosition: currentDragPosition ?? this.currentDragPosition,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      isDraggedTaskHiddenFromExpansion: isDraggedTaskHiddenFromExpansion ??
          this.isDraggedTaskHiddenFromExpansion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TasksSectionDragState &&
        other.draggedTask == draggedTask &&
        other.hoveredInsertionIndex == hoveredInsertionIndex &&
        other.hoveredTaskId == hoveredTaskId &&
        other.dragStartPosition == dragStartPosition &&
        other.currentDragPosition == currentDragPosition &&
        other.horizontalOffset == horizontalOffset &&
        other.verticalOffset == verticalOffset &&
        other.isDraggedTaskHiddenFromExpansion ==
            isDraggedTaskHiddenFromExpansion;
  }

  @override
  int get hashCode {
    return draggedTask.hashCode ^
        hoveredInsertionIndex.hashCode ^
        hoveredTaskId.hashCode ^
        dragStartPosition.hashCode ^
        currentDragPosition.hashCode ^
        horizontalOffset.hashCode ^
        verticalOffset.hashCode ^
        isDraggedTaskHiddenFromExpansion.hashCode;
  }
}

/// Tasks Section 拖拽状态管理
class TasksSectionDragNotifier extends StateNotifier<TasksSectionDragState> {
  TasksSectionDragNotifier() : super(const TasksSectionDragState());

  /// 开始拖拽
  ///
  /// [task] 被拖拽的任务
  /// [startPosition] 拖拽起始位置（全局坐标）
  void startDrag(Task task, Offset startPosition) {
    state = TasksSectionDragState(
      draggedTask: task,
      dragStartPosition: startPosition,
      currentDragPosition: startPosition,
      horizontalOffset: 0.0,
      verticalOffset: 0.0,
    );
  }

  void endDrag() {
    state = const TasksSectionDragState();
  }

  /// 设置被拖拽任务在UI上的隐藏状态（用于子任务移出扩展区时）
  ///
  /// [hidden] true 表示隐藏，false 表示显示，null 表示重置
  void setDraggedTaskHidden(bool? hidden) {
    state = state.copyWith(isDraggedTaskHiddenFromExpansion: hidden);
  }

  /// 更新拖拽位置
  ///
  /// [position] 当前拖拽位置（全局坐标）
  /// 自动计算水平位移（dx）和垂直位移（dy）
  void updateDragPosition(Offset position) {
    if (state.dragStartPosition == null) {
      // 如果起始位置不存在，使用当前位置作为起始位置
      state = state.copyWith(
        dragStartPosition: position,
        currentDragPosition: position,
        horizontalOffset: 0.0,
        verticalOffset: 0.0,
      );
      return;
    }

    // 如果起始位置是 Offset.zero（占位符），将其更新为第一次的实际位置
    final startPos = state.dragStartPosition!;
    if (startPos == Offset.zero && state.currentDragPosition == Offset.zero) {
      // 第一次更新：将起始位置设置为当前位置
      state = state.copyWith(
        dragStartPosition: position,
        currentDragPosition: position,
        horizontalOffset: 0.0,
        verticalOffset: 0.0,
      );
      return;
    }

    final dx = position.dx - state.dragStartPosition!.dx;
    final dy = position.dy - state.dragStartPosition!.dy;
    state = state.copyWith(
      currentDragPosition: position,
      horizontalOffset: dx,
      verticalOffset: dy,
    );
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

/// Tasks Section 拖拽状态 Provider (按分区管理)
///
/// 使用 StateNotifierProvider.family 按分区分别管理拖拽状态
///
/// 使用方式：
/// ```dart
/// final dragState = ref.watch(tasksSectionDragProvider(TaskSection.today));
/// ```
final tasksSectionDragProvider =
    StateNotifierProvider.family<TasksSectionDragNotifier, TasksSectionDragState,
        TaskSection>((ref, section) {
  return TasksSectionDragNotifier();
});

