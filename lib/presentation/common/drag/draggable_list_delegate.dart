import 'package:flutter/material.dart';

/// 拖拽列表的行为委托接口
/// 
/// 定义了跨区域拖拽列表的所有行为接口，支持：
/// - 同区域内的重排序
/// - 接收外部拖拽的任务
/// - 任务成为子任务
/// - 子任务提升为根任务
abstract class DraggableListDelegate<T extends Object> {
  /// 是否可以在同区域内重排序
  bool canReorder(T item, int oldIndex, int newIndex);
  
  /// 处理同区域内的重排序
  Future<void> onReorder(T item, int oldIndex, int newIndex);
  
  /// 是否可以接收外部拖拽的任务
  bool canAcceptExternal(T draggedItem, int targetIndex);
  
  /// 处理接收外部拖拽的任务
  Future<void> onAcceptExternal(T draggedItem, int targetIndex);
  
  /// 是否可以将一个任务拖拽成为另一个任务的子任务
  bool canMakeChild(T draggedItem, T targetItem);
  
  /// 处理任务成为子任务
  Future<void> onMakeChild(T draggedItem, T targetItem);
  
  /// 是否可以将子任务提升为根任务
  bool canPromoteToRoot(T item);
  
  /// 处理子任务提升为根任务
  Future<void> onPromoteToRoot(T item);
  
  /// 获取任务的唯一标识符
  String getItemId(T item);
  
  /// 构建任务的显示组件
  Widget buildItem(BuildContext context, T item, int index, Animation<double> animation);
  
  /// 构建拖拽时的反馈组件（可选）
  Widget? buildDragFeedback(BuildContext context, T item) => null;
  
  /// 构建提升为根任务的目标区域（可选）
  Widget? buildPromoteTarget(BuildContext context) => null;
}

/// 拖拽事件回调
class DragEventCallbacks {
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final void Function(bool isHovering)? onHoverChanged;
  
  const DragEventCallbacks({
    this.onDragStarted,
    this.onDragEnd,
    this.onHoverChanged,
  });
}
