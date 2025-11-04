import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../presentation/common/task_list/task_list_edge_auto_scroll.dart';
import '../../presentation/tasks/tasks_drag_target_type.dart';
import 'tasks_drag_provider/tasks_drag_auto_scroll_mixin.dart';

/// Tasks页面拖拽状态
class TasksDragState {
  final Task? draggedTask;
  final TasksDragTargetType? hoverTarget;
  final int? hoverTargetId; // 用于区分同类型的不同目标
  final bool isDragging;
  
  // 统一拖拽系统：当前悬停的插入位置索引（该 section 内的索引）
  final int? hoveredInsertionIndex;
  // 统一拖拽系统：当前悬停的插入位置所在的 section
  final TaskSection? hoveredInsertionSection;
  // 统一拖拽系统：当前悬停的任务 ID
  final int? hoveredTaskId;
  // 已提交的插入位置索引（让位动画触发时的位置，即使后续hover状态变化也保留）
  final int? committedInsertionIndex;
  // 已提交的插入位置所在的 section
  final TaskSection? committedInsertionSection;
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
  
  const TasksDragState({
    this.draggedTask,
    this.hoverTarget,
    this.hoverTargetId,
    this.isDragging = false,
    this.hoveredInsertionIndex,
    this.hoveredInsertionSection,
    this.hoveredTaskId,
    this.committedInsertionIndex,
    this.committedInsertionSection,
    this.dragStartPosition,
    this.currentDragPosition,
    this.horizontalOffset,
    this.verticalOffset,
    this.isDraggedTaskHiddenFromExpansion,
  });

  TasksDragState copyWith({
    Task? draggedTask,
    TasksDragTargetType? hoverTarget,
    int? hoverTargetId,
    bool? isDragging,
    int? hoveredInsertionIndex,
    TaskSection? hoveredInsertionSection,
    int? hoveredTaskId,
    int? committedInsertionIndex,
    TaskSection? committedInsertionSection,
    Offset? dragStartPosition,
    Offset? currentDragPosition,
    double? horizontalOffset,
    double? verticalOffset,
    bool? isDraggedTaskHiddenFromExpansion,
  }) {
    return TasksDragState(
      draggedTask: draggedTask ?? this.draggedTask,
      hoverTarget: hoverTarget ?? this.hoverTarget,
      hoverTargetId: hoverTargetId ?? this.hoverTargetId,
      isDragging: isDragging ?? this.isDragging,
      hoveredInsertionIndex: hoveredInsertionIndex ?? this.hoveredInsertionIndex,
      hoveredInsertionSection: hoveredInsertionSection ?? this.hoveredInsertionSection,
      hoveredTaskId: hoveredTaskId ?? this.hoveredTaskId,
      committedInsertionIndex: committedInsertionIndex ?? this.committedInsertionIndex,
      committedInsertionSection: committedInsertionSection ?? this.committedInsertionSection,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      currentDragPosition: currentDragPosition ?? this.currentDragPosition,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      isDraggedTaskHiddenFromExpansion: isDraggedTaskHiddenFromExpansion ?? this.isDraggedTaskHiddenFromExpansion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TasksDragState &&
        other.draggedTask == draggedTask &&
        other.hoverTarget == hoverTarget &&
        other.hoverTargetId == hoverTargetId &&
        other.isDragging == isDragging &&
        other.hoveredInsertionIndex == hoveredInsertionIndex &&
        other.hoveredInsertionSection == hoveredInsertionSection &&
        other.hoveredTaskId == hoveredTaskId &&
        other.committedInsertionIndex == committedInsertionIndex &&
        other.committedInsertionSection == committedInsertionSection &&
        other.dragStartPosition == dragStartPosition &&
        other.currentDragPosition == currentDragPosition &&
        other.horizontalOffset == horizontalOffset &&
        other.verticalOffset == verticalOffset &&
        other.isDraggedTaskHiddenFromExpansion == isDraggedTaskHiddenFromExpansion;
  }

  @override
  int get hashCode {
    return draggedTask.hashCode ^
        hoverTarget.hashCode ^
        hoverTargetId.hashCode ^
        isDragging.hashCode ^
        hoveredInsertionIndex.hashCode ^
        hoveredInsertionSection.hashCode ^
        hoveredTaskId.hashCode ^
        committedInsertionIndex.hashCode ^
        committedInsertionSection.hashCode ^
        dragStartPosition.hashCode ^
        currentDragPosition.hashCode ^
        horizontalOffset.hashCode ^
        verticalOffset.hashCode ^
        isDraggedTaskHiddenFromExpansion.hashCode;
  }
}

/// Tasks页面拖拽状态管理器
class TasksDragNotifier extends StateNotifier<TasksDragState>
    with TasksDragAutoScrollMixin
    implements DragNotifierWithAutoScroll {
  TasksDragNotifier() : super(const TasksDragState());
  
  /// 开始拖拽
  ///
  /// [task] 被拖拽的任务
  /// [startPosition] 拖拽起始位置（全局坐标）
  void startDrag(Task task, Offset startPosition) {
    // 保存当前滚动位置（用于拖拽结束后恢复）
    saveScrollPositionBeforeDrag();
    
    state = TasksDragState(
      draggedTask: task,
      isDragging: true,
      dragStartPosition: startPosition,
      currentDragPosition: startPosition,
      horizontalOffset: 0.0,
      verticalOffset: 0.0,
    );
  }
  
  /// 更新悬停目标（保留以向后兼容）
  void updateHoverTarget(TasksDragTargetType? targetType, {int? targetId}) {
    state = state.copyWith(
      hoverTarget: targetType,
      hoverTargetId: targetId,
    );
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
  void updateInsertionHover(int? insertionIndex, TaskSection? section) {
    // 当新的插入索引不为 null 且与当前不同时，记录为已提交位置
    int? newCommittedIndex;
    TaskSection? newCommittedSection;
    if (insertionIndex != null && 
        (insertionIndex != state.hoveredInsertionIndex || 
         section != state.hoveredInsertionSection)) {
      // 插入位置改变，记录为已提交位置
      newCommittedIndex = insertionIndex;
      newCommittedSection = section;
    } else {
      // 保持当前的已提交位置不变
      newCommittedIndex = state.committedInsertionIndex;
      newCommittedSection = state.committedInsertionSection;
    }
    
    state = state.copyWith(
      hoveredInsertionIndex: insertionIndex,
      hoveredInsertionSection: section,
      hoveredTaskId: null, // 清除任务表面悬停
      committedInsertionIndex: newCommittedIndex,
      committedInsertionSection: newCommittedSection,
    );
  }
  
  /// 统一拖拽系统：更新任务表面悬停状态
  void updateTaskSurfaceHover(int? taskId) {
    state = state.copyWith(
      hoveredTaskId: taskId,
      hoveredInsertionIndex: null, // 清除插入位置悬停
    );
  }
  
  /// 设置被拖拽任务在UI上的隐藏状态（用于子任务移出扩展区时）
  ///
  /// [hidden] true 表示隐藏，false 表示显示，null 表示重置
  void setDraggedTaskHidden(bool? hidden) {
    state = state.copyWith(isDraggedTaskHiddenFromExpansion: hidden);
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
  
  // 自动滚动相关方法已移至 TasksDragAutoScrollMixin
  
  /// 结束拖拽
  void endDrag() {
    // 拖拽结束时停止自动滚动
    stopAutoScroll();
    
    // 保存滚动位置（将在下一个 frame 恢复）
    final savedScrollPosition = scrollPositionBeforeDrag;
    clearScrollPositionBeforeDrag();
    
    // 拖拽结束时清除所有状态，包括已提交的插入位置
    state = const TasksDragState();
    
    // 恢复滚动位置
    if (savedScrollPosition != null) {
      restoreScrollPosition();
    }
  }
  
}

/// Tasks页面拖拽状态Provider
final tasksDragProvider = StateNotifierProvider<TasksDragNotifier, TasksDragState>(
  (ref) => TasksDragNotifier(),
);
