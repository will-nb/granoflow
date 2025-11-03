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
    this.committedInsertionIndex,
  });

  final Task? draggedTask;
  // 统一拖拽系统：当前悬停的插入位置索引
  final int? hoveredInsertionIndex;
  // 统一拖拽系统：当前悬停的任务 ID
  final int? hoveredTaskId;
  // 已提交的插入位置索引（让位动画触发时的位置，即使后续hover状态变化也保留）
  final int? committedInsertionIndex;
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
    int? committedInsertionIndex,
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
      committedInsertionIndex: committedInsertionIndex ?? this.committedInsertionIndex,
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
            isDraggedTaskHiddenFromExpansion &&
        other.committedInsertionIndex == committedInsertionIndex;
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
        isDraggedTaskHiddenFromExpansion.hashCode ^
        committedInsertionIndex.hashCode;
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
    // 拖拽结束时清除所有状态，包括已提交的插入位置
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
    // 如果起始位置不存在或者是占位符（Offset.zero），设置为当前位置
    if (state.dragStartPosition == null || state.dragStartPosition == Offset.zero) {
      state = state.copyWith(
        dragStartPosition: position,
        currentDragPosition: position,
        horizontalOffset: 0.0,
        verticalOffset: 0.0,
      );
      return;
    }

    // 计算相对于起始位置的偏移量
    final dx = position.dx - state.dragStartPosition!.dx;
    final dy = position.dy - state.dragStartPosition!.dy;
    state = state.copyWith(
      currentDragPosition: position,
      horizontalOffset: dx,
      verticalOffset: dy,
    );
  }

  /// 统一拖拽系统：更新插入位置悬停状态
  /// 
  /// 当插入位置改变时，记录为已提交位置（committedInsertionIndex），
  /// 这样即使后续hover状态变化，也能记住让位动画触发时的插入位置
  void updateInsertionHover(int? insertionIndex) {
    // 当新的插入索引不为 null 且与当前不同时，记录为已提交位置
    int? newCommittedIndex;
    if (insertionIndex != null && 
        insertionIndex != state.hoveredInsertionIndex) {
      // 插入位置改变，记录为已提交位置
      newCommittedIndex = insertionIndex;
    } else {
      // 保持当前的已提交位置不变
      newCommittedIndex = state.committedInsertionIndex;
    }
    
    state = state.copyWith(
      hoveredInsertionIndex: insertionIndex,
      hoveredTaskId: null, // 清除任务表面悬停
      committedInsertionIndex: newCommittedIndex,
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
  /// 
  /// 注意：只清除 hover 状态，保留 committedInsertionIndex（已提交的插入位置）
  /// 这样即使离开插入区域，仍能记住之前让位动画触发时的位置
  void clearHover() {
    // 即使已经是清除状态，也要触发更新，确保 UI 能正确还原
    if (state.hoveredInsertionIndex == null && state.hoveredTaskId == null) {
      // 如果已经是清除状态，不需要重复更新
      return;
    }
    state = state.copyWith(
      hoveredInsertionIndex: null,
      hoveredTaskId: null,
      // 不清除 committedInsertionIndex，保留已提交的位置
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

