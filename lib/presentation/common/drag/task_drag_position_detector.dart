import 'package:flutter/material.dart';
import '../../../core/constants/drag_constants.dart';
import '../../../data/models/task.dart';

/// 拖拽意图枚举
/// 
/// 表示用户在拖拽过程中的意图：
/// - [sorting]: 在两个任务之间插入（排序）
/// - [dragIn]: 将任务拖到另一个任务上（移入，使其成为子任务）
/// - [none]: 未确定意图或无有效意图
enum DragIntent {
  /// 排序：在两个任务之间插入
  sorting,
  
  /// 移入：将任务拖到另一个任务上，使其成为子任务
  dragIn,
  
  /// 未确定意图
  none,
}

/// 插入位置信息
/// 
/// 包含插入位置的索引和相关信息
class InsertionPosition {
  const InsertionPosition({
    required this.index,
    required this.beforeTask,
    this.afterTask,
  });

  /// 插入位置索引（插入到这个索引之前）
  final int index;
  
  /// 前面的任务（可以为 null，表示插入到列表开头）
  final Task? beforeTask;
  
  /// 后面的任务（可以为 null，表示插入到列表结尾）
  final Task? afterTask;
}

/// 任务表面位置信息
/// 
/// 包含任务表面（用于移入）的位置信息
class TaskSurfacePosition {
  const TaskSurfacePosition({
    required this.task,
    required this.isInMiddleZone,
  });

  /// 目标任务
  final Task task;
  
  /// 是否在任务中间区域（排除上下边缘 16 像素）
  final bool isInMiddleZone;
}

/// 任务拖拽位置检测工具类
/// 
/// 用于检测拖拽过程中鼠标位置，判断用户意图（排序 vs 移入）
/// 
/// 检测逻辑：
/// 1. 如果鼠标在插入容错区间内（34 像素总高度）→ 判定为排序
/// 2. 如果鼠标在任务中间区域（排除上下边缘 16 像素）→ 判定为移入
/// 3. 优先级：插入优先于移入（在重叠区域）
class TaskDragPositionDetector {
  /// 检测拖拽意图
  /// 
  /// 根据全局坐标和任务列表信息，判断用户当前的拖拽意图。
  /// 
  /// [globalPosition] 鼠标的全局坐标
  /// [insertionTargets] 插入目标列表，每个元素包含插入位置的 RenderBox 和索引
  /// [taskSurfaces] 任务表面列表，每个元素包含任务的 RenderBox、任务对象和索引
  /// 
  /// 返回 [DragIntent] 枚举，表示检测到的用户意图
  static DragIntent detectIntent({
    required Offset globalPosition,
    required List<({RenderBox box, int index})> insertionTargets,
    required List<({RenderBox box, Task task, int index})> taskSurfaces,
  }) {
    // 首先检查是否在插入容错区间内（优先级最高）
    for (final insertion in insertionTargets) {
      if (_isInInsertionZone(globalPosition, insertion.box)) {
        return DragIntent.sorting;
      }
    }
    
    // 然后检查是否在任务中间区域
    for (final surface in taskSurfaces) {
      if (_isInTaskMiddleZone(globalPosition, surface.box)) {
        return DragIntent.dragIn;
      }
    }
    
    return DragIntent.none;
  }

  /// 查找插入位置
  /// 
  /// 根据全局坐标查找对应的插入位置。
  /// 
  /// [globalPosition] 鼠标的全局坐标
  /// [insertionTargets] 插入目标列表，每个元素包含插入位置的 RenderBox、索引和前后任务信息
  /// 
  /// 返回 [InsertionPosition] 对象，如果未找到则返回 null
  static InsertionPosition? findInsertionPosition({
    required Offset globalPosition,
    required List<({
      RenderBox box,
      int index,
      Task? beforeTask,
      Task? afterTask,
    })> insertionTargets,
  }) {
    for (final insertion in insertionTargets) {
      if (_isInInsertionZone(globalPosition, insertion.box)) {
        return InsertionPosition(
          index: insertion.index,
          beforeTask: insertion.beforeTask,
          afterTask: insertion.afterTask,
        );
      }
    }
    return null;
  }

  /// 查找任务表面位置
  /// 
  /// 根据全局坐标查找对应的任务表面位置。
  /// 
  /// [globalPosition] 鼠标的全局坐标
  /// [taskSurfaces] 任务表面列表，每个元素包含任务的 RenderBox、任务对象和索引
  /// 
  /// 返回 [TaskSurfacePosition] 对象，如果未找到则返回 null
  static TaskSurfacePosition? findTaskSurface({
    required Offset globalPosition,
    required List<({RenderBox box, Task task, int index})> taskSurfaces,
  }) {
    for (final surface in taskSurfaces) {
      final isInMiddleZone = _isInTaskMiddleZone(globalPosition, surface.box);
      if (isInMiddleZone || _isInTaskSurface(globalPosition, surface.box)) {
        return TaskSurfacePosition(
          task: surface.task,
          isInMiddleZone: isInMiddleZone,
        );
      }
    }
    return null;
  }

  /// 检查全局坐标是否在插入容错区间内
  /// 
  /// 插入容错区间总高度为 34 像素（基础 2 像素 + 上下各 16 像素容错区间）
  /// 这个容错区间用于支持移动让位动画，确保用户可以轻松在两个任务之间插入
  /// 
  /// [globalPosition] 全局坐标
  /// [insertionBox] 插入目标的 RenderBox
  static bool _isInInsertionZone(
    Offset globalPosition,
    RenderBox insertionBox,
  ) {
    try {
      final localPosition = insertionBox.globalToLocal(globalPosition);
      final size = insertionBox.size;
      
      // 检查是否在插入目标范围内
      // 插入目标总高度为 insertionTargetHeight (34 像素)
      return localPosition.dy >= 0 &&
          localPosition.dy <= size.height &&
          localPosition.dx >= 0 &&
          localPosition.dx <= size.width;
    } catch (e) {
      // 如果坐标转换失败，返回 false
      return false;
    }
  }

  /// 检查全局坐标是否在任务中间区域
  /// 
  /// 任务中间区域 = 任务总高度 - 上下边缘各 16 像素
  /// 
  /// [globalPosition] 全局坐标
  /// [taskBox] 任务表面的 RenderBox
  static bool _isInTaskMiddleZone(
    Offset globalPosition,
    RenderBox taskBox,
  ) {
    try {
      final localPosition = taskBox.globalToLocal(globalPosition);
      final size = taskBox.size;
      
      // 排除上下边缘各 16 像素
      final exclusionZone = DragConstants.taskSurfaceExclusionZone;
      return localPosition.dy >= exclusionZone &&
          localPosition.dy <= (size.height - exclusionZone) &&
          localPosition.dx >= 0 &&
          localPosition.dx <= size.width;
    } catch (e) {
      // 如果坐标转换失败，返回 false
      return false;
    }
  }

  /// 检查全局坐标是否在任务表面范围内（包括边缘区域）
  /// 
  /// [globalPosition] 全局坐标
  /// [taskBox] 任务表面的 RenderBox
  static bool _isInTaskSurface(
    Offset globalPosition,
    RenderBox taskBox,
  ) {
    try {
      final localPosition = taskBox.globalToLocal(globalPosition);
      final size = taskBox.size;
      
      // 检查是否在任务表面范围内（包括边缘）
      return localPosition.dy >= 0 &&
          localPosition.dy <= size.height &&
          localPosition.dx >= 0 &&
          localPosition.dx <= size.width;
    } catch (e) {
      // 如果坐标转换失败，返回 false
      return false;
    }
  }
}

