import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../presentation/common/task_list/task_list_edge_auto_scroll.dart';

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
    this.dragStartPosition,
    this.currentDragPosition,
    this.horizontalOffset,
    this.verticalOffset,
    this.isDraggedTaskHiddenFromExpansion,
    this.committedInsertionIndex,
  });

  final Task? draggedTask;
  final InboxDragTargetType? hoverTarget;
  final int? hoverTargetId;
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

  InboxDragState copyWith({
    Task? draggedTask,
    InboxDragTargetType? hoverTarget,
    int? hoverTargetId,
    int? hoveredInsertionIndex,
    int? hoveredTaskId,
    Offset? dragStartPosition,
    Offset? currentDragPosition,
    double? horizontalOffset,
    double? verticalOffset,
    bool? isDraggedTaskHiddenFromExpansion,
    int? committedInsertionIndex,
  }) {
    return InboxDragState(
      draggedTask: draggedTask ?? this.draggedTask,
      hoverTarget: hoverTarget ?? this.hoverTarget,
      hoverTargetId: hoverTargetId ?? this.hoverTargetId,
      hoveredInsertionIndex: hoveredInsertionIndex ?? this.hoveredInsertionIndex,
      hoveredTaskId: hoveredTaskId ?? this.hoveredTaskId,
      dragStartPosition: dragStartPosition ?? this.dragStartPosition,
      currentDragPosition: currentDragPosition ?? this.currentDragPosition,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      isDraggedTaskHiddenFromExpansion: isDraggedTaskHiddenFromExpansion ?? this.isDraggedTaskHiddenFromExpansion,
      committedInsertionIndex: committedInsertionIndex ?? this.committedInsertionIndex,
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
        other.hoveredTaskId == hoveredTaskId &&
        other.dragStartPosition == dragStartPosition &&
        other.currentDragPosition == currentDragPosition &&
        other.horizontalOffset == horizontalOffset &&
        other.verticalOffset == verticalOffset &&
        other.isDraggedTaskHiddenFromExpansion == isDraggedTaskHiddenFromExpansion &&
        other.committedInsertionIndex == committedInsertionIndex;
  }

  @override
  int get hashCode {
    return draggedTask.hashCode ^
        hoverTarget.hashCode ^
        hoverTargetId.hashCode ^
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

/// Inbox 拖拽状态管理
class InboxDragNotifier extends StateNotifier<InboxDragState>
    implements DragNotifierWithAutoScroll {
  InboxDragNotifier() : super(const InboxDragState());

  /// 是否正在自动滚动
  bool _isAutoScrolling = false;

  /// 自动滚动定时器（用于持续滚动）
  Timer? _autoScrollTimer;

  /// 当前滚动控制器（需要在外部设置）
  ScrollController? _scrollController;

  /// 拖拽开始时的滚动位置（用于拖拽结束后恢复）
  double? _scrollPositionBeforeDrag;

  /// 设置滚动控制器
  @override
  void setScrollController(ScrollController? controller) {
    _scrollController = controller;
  }

  /// 开始边缘自动滚动
  ///
  /// [direction] 滚动方向：正数向下，负数向上
  /// [speed] 滚动速度（像素/次），默认 30px
  @override
  void startAutoScroll(double direction, {double speed = 30.0}) {
    if (_isAutoScrolling && _scrollController != null && _scrollController!.hasClients) {
      // 已经在滚动，更新方向
      _updateAutoScroll(direction, speed);
      return;
    }

    if (_scrollController == null || !_scrollController!.hasClients) {
      return; // 没有有效的滚动控制器
    }

    _isAutoScrolling = true;
    _updateAutoScroll(direction, speed);
  }

  /// 更新自动滚动
  void _updateAutoScroll(double direction, double speed) {
    _autoScrollTimer?.cancel();

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController == null || !_scrollController!.hasClients) {
        stopAutoScroll();
        return;
      }

      final scrollPosition = _scrollController!.position;
      final currentOffset = scrollPosition.pixels;
      final maxScroll = scrollPosition.maxScrollExtent;
      final minScroll = scrollPosition.minScrollExtent;

      // 计算新位置
      double newOffset = currentOffset + (direction * speed);

      // 限制在边界内（但不停止滚动，由检测逻辑统一决定停止）
      if (newOffset < minScroll) {
        newOffset = minScroll;
      } else if (newOffset > maxScroll) {
        newOffset = maxScroll;
      }

      // 执行滚动（即使到达边界也执行，确保位置被正确限制）
      // 只在位置变化时执行，避免无效调用
      if (currentOffset != newOffset) {
        _scrollController!.jumpTo(newOffset);
      }
      // 定时器继续运行，等待下一次检测逻辑的决策
    });
  }

  /// 停止边缘自动滚动
  @override
  void stopAutoScroll() {
    _isAutoScrolling = false;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  /// 开始拖拽
  ///
  /// [task] 被拖拽的任务
  /// [startPosition] 拖拽起始位置（全局坐标）
  void startDrag(Task task, Offset startPosition) {
    // 保存当前滚动位置（用于拖拽结束后恢复）
    if (_scrollController != null && _scrollController!.hasClients) {
      _scrollPositionBeforeDrag = _scrollController!.position.pixels;
    }

    state = InboxDragState(
      draggedTask: task,
      dragStartPosition: startPosition,
      currentDragPosition: startPosition,
      horizontalOffset: 0.0,
      verticalOffset: 0.0,
    );
  }

  void endDrag() {
    // 拖拽结束时停止自动滚动
    stopAutoScroll();

    // 保存滚动位置（将在下一个 frame 恢复）
    final savedScrollPosition = _scrollPositionBeforeDrag;
    _scrollPositionBeforeDrag = null;

    // 拖拽结束时清除所有状态，包括已提交的插入位置
    state = const InboxDragState();

    // 在下一个 frame 恢复滚动位置（确保在数据更新重建之后）
    if (savedScrollPosition != null && _scrollController != null && _scrollController!.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController != null && _scrollController!.hasClients) {
          _scrollController!.jumpTo(savedScrollPosition);
        }
      });
    }
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

  void updateHoverTarget(InboxDragTargetType? type, {int? targetId}) {
    state = state.copyWith(hoverTarget: type, hoverTargetId: targetId);
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

/// Inbox 拖拽状态 Provider
final inboxDragProvider = StateNotifierProvider<InboxDragNotifier, InboxDragState>((ref) {
  return InboxDragNotifier();
});
