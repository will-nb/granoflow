import 'package:flutter/foundation.dart';
import '../../../data/models/task.dart';
import 'task_drag_position_detector.dart';

/// 统一拖拽状态管理器
/// 
/// 管理统一拖拽系统的状态，包括：
/// - 当前拖拽的任务
/// - 当前悬停的插入位置索引
/// - 当前悬停的任务 ID
/// - 当前拖拽意图
/// 
/// 使用 [ChangeNotifier] 提供状态变更通知，供 UI 组件监听并更新视觉反馈。
class UnifiedDragStateManager extends ChangeNotifier {
  /// 当前拖拽的任务
  Task? _draggedTask;
  
  /// 当前悬停的插入位置索引（null 表示未悬停在插入位置）
  int? _hoveredInsertionIndex;
  
    /// 当前悬停的任务 ID（null 表示未悬停在任务表面）
    String? _hoveredTaskId;
  
  /// 当前拖拽意图
  DragIntent _currentIntent = DragIntent.none;

  /// 获取当前拖拽的任务
  Task? get draggedTask => _draggedTask;

  /// 获取当前悬停的插入位置索引
  int? get hoveredInsertionIndex => _hoveredInsertionIndex;

    /// 获取当前悬停的任务 ID
    String? get hoveredTaskId => _hoveredTaskId;

  /// 获取当前拖拽意图
  DragIntent get currentIntent => _currentIntent;

  /// 是否正在拖拽
  bool get isDragging => _draggedTask != null;

  /// 开始拖拽
  /// 
  /// [task] 被拖拽的任务
  void startDrag(Task task) {
    if (_draggedTask?.id == task.id) {
      // 如果已经在拖拽同一个任务，不重复设置
      return;
    }
    
    _draggedTask = task;
    _hoveredInsertionIndex = null;
    _hoveredTaskId = null;
    _currentIntent = DragIntent.none;
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint(
        '[UnifiedDragState] Started drag: task=${task.id}, title="${task.title}"',
      );
    }
  }

  /// 更新悬停状态
  /// 
  /// 根据检测到的拖拽意图更新状态：
  /// - 如果意图是排序（sorting），更新 [hoveredInsertionIndex]
  /// - 如果意图是移入（dragIn），更新 [hoveredTaskId]
  /// - 如果意图是无（none），清除所有悬停状态
  /// 
  /// [intent] 检测到的拖拽意图
  /// [insertionIndex] 插入位置索引（仅在 intent == DragIntent.sorting 时使用）
  /// [taskId] 任务 ID（仅在 intent == DragIntent.dragIn 时使用）
  void updateHover({
    required DragIntent intent,
      int? insertionIndex,
      String? taskId,
  }) {
    if (!isDragging) {
      // 如果不在拖拽状态，忽略悬停更新
      return;
    }

    bool changed = false;

    // 更新插入位置索引
    if (intent == DragIntent.sorting) {
      if (_hoveredInsertionIndex != insertionIndex) {
        _hoveredInsertionIndex = insertionIndex;
        _hoveredTaskId = null; // 清除任务表面悬停
        changed = true;
      }
    } else {
      if (_hoveredInsertionIndex != null) {
        _hoveredInsertionIndex = null;
        changed = true;
      }
    }

    // 更新任务表面悬停
    if (intent == DragIntent.dragIn) {
      if (_hoveredTaskId != taskId) {
        _hoveredTaskId = taskId;
        _hoveredInsertionIndex = null; // 清除插入位置悬停
        changed = true;
      }
    } else {
      if (_hoveredTaskId != null) {
        _hoveredTaskId = null;
        changed = true;
      }
    }

    // 更新当前意图
    if (_currentIntent != intent) {
      _currentIntent = intent;
      changed = true;
    }

    if (changed) {
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint(
          '[UnifiedDragState] Updated hover: intent=$intent, '
          'insertionIndex=$insertionIndex, taskId=$taskId',
        );
      }
    }
  }

  /// 清除悬停状态（但不结束拖拽）
  /// 
  /// 用于鼠标离开所有目标区域时调用
  void clearHover() {
    if (_hoveredInsertionIndex == null && _hoveredTaskId == null) {
      // 如果已经是清除状态，不重复通知
      return;
    }

    _hoveredInsertionIndex = null;
    _hoveredTaskId = null;
    _currentIntent = DragIntent.none;
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('[UnifiedDragState] Cleared hover');
    }
  }

  /// 结束拖拽
  /// 
  /// 清除所有拖拽相关状态
  void endDrag() {
    if (!isDragging) {
      // 如果不在拖拽状态，不重复清除
      return;
    }

    final taskId = _draggedTask?.id;
    _draggedTask = null;
    _hoveredInsertionIndex = null;
    _hoveredTaskId = null;
    _currentIntent = DragIntent.none;
    notifyListeners();
    
    if (kDebugMode) {
      debugPrint('[UnifiedDragState] Ended drag: task=$taskId');
    }
  }

  /// 重置所有状态
  /// 
  /// 清除所有状态，通常在组件销毁时调用
  @override
  void dispose() {
    _draggedTask = null;
    _hoveredInsertionIndex = null;
    _hoveredTaskId = null;
    _currentIntent = DragIntent.none;
    super.dispose();
  }
}

