import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 拖拽列表控制器
/// 
/// 管理拖拽状态、动画控制、手势优先级和自动滚动
class DraggableListController<T extends Object> extends ChangeNotifier {
  // 动画控制
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<T> _items = [];
  
  // 拖拽状态
  T? _draggedItem;
  int? _draggedIndex;
  int? _hoverIndex;
  bool _isDragging = false;
  
  // 自动滚动
  ScrollController? _scrollController;
  Timer? _autoScrollTimer;
  static const double _autoScrollThreshold = 50.0;
  static const double _autoScrollSpeed = 5.0;
  
  // Getters
  GlobalKey<AnimatedListState> get listKey => _listKey;
  List<T> get items => List.unmodifiable(_items);
  bool get isDragging => _isDragging;
  T? get draggedItem => _draggedItem;
  int? get draggedIndex => _draggedIndex;
  int? get hoverIndex => _hoverIndex;
  
  /// 初始化列表数据
  void initItems(List<T> items) {
    _items.clear();
    _items.addAll(items);
    notifyListeners();
  }
  
  /// 更新列表数据（不触发动画）
  void updateItems(List<T> items) {
    _items.clear();
    _items.addAll(items);
    notifyListeners();
  }
  
  /// 设置滚动控制器
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }
  
  /// 开始拖拽
  void startDrag(T item, int index) {
    if (kDebugMode) {
      debugPrint('[DragController] startDrag - item: $item, index: $index, currentItems: ${_items.length}');
    }
    
    _draggedItem = item;
    _draggedIndex = index;
    _isDragging = true;
    notifyListeners();
  }
  
  /// 更新悬停位置
  void updateHoverIndex(int? index) {
    if (_hoverIndex != index) {
      if (kDebugMode) {
        debugPrint('[DragController] updateHoverIndex - old: $_hoverIndex, new: $index');
      }
      
      _hoverIndex = index;
      notifyListeners();
    }
  }
  
  /// 结束拖拽
  void endDrag() {
    if (kDebugMode) {
      debugPrint('[DragController] endDrag - draggedItem: $_draggedItem, draggedIndex: $_draggedIndex, hoverIndex: $_hoverIndex');
    }
    
    _draggedItem = null;
    _draggedIndex = null;
    _hoverIndex = null;
    _isDragging = false;
    _stopAutoScroll();
    notifyListeners();
  }
  
  /// 在列表中插入项目（带动画）
  void insertItem(int index, T item, {Duration duration = const Duration(milliseconds: 300)}) {
    _items.insert(index, item);
    _listKey.currentState?.insertItem(index, duration: duration);
    notifyListeners();
  }
  
  /// 从列表中移除项目（带动画）
  void removeItem(int index, Widget Function(BuildContext, Animation<double>) builder,
      {Duration duration = const Duration(milliseconds: 300)}) {
    _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => builder(context, animation),
      duration: duration,
    );
    notifyListeners();
  }
  
  /// 移动项目（不触发动画，用于实时拖拽反馈）
  void moveItem(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      if (kDebugMode) {
        debugPrint('[DragController] moveItem - same index, skipping');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('[DragController] moveItem - oldIndex: $oldIndex, newIndex: $newIndex, itemsCount: ${_items.length}');
    }
    
    final item = _items.removeAt(oldIndex);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _items.insert(targetIndex, item);
    
    // 更新拖拽索引
    if (_draggedIndex == oldIndex) {
      _draggedIndex = targetIndex;
    }
    
    notifyListeners();
  }
  
  /// 开始自动滚动
  void startAutoScroll(DragUpdateDetails details, BuildContext context) {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final scrollPosition = _scrollController!.position;
    
    // 计算是否需要自动滚动
    double? scrollDelta;
    if (localPosition.dy < _autoScrollThreshold) {
      // 向上滚动
      scrollDelta = -_autoScrollSpeed;
    } else if (localPosition.dy > renderBox.size.height - _autoScrollThreshold) {
      // 向下滚动
      scrollDelta = _autoScrollSpeed;
    }
    
    if (scrollDelta != null) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!_scrollController!.hasClients) {
          timer.cancel();
          return;
        }
        
        final newOffset = scrollPosition.pixels + scrollDelta!;
        if (newOffset >= scrollPosition.minScrollExtent &&
            newOffset <= scrollPosition.maxScrollExtent) {
          scrollPosition.jumpTo(newOffset);
        }
      });
    } else {
      _stopAutoScroll();
    }
  }
  
  /// 停止自动滚动
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }
  
  /// 计算插入位置的间隙索引
  int calculateGapIndex(Offset position, BuildContext context) {
    final RenderBox listBox = context.findRenderObject() as RenderBox;
    final localPosition = listBox.globalToLocal(position);
    
    // 简单实现：根据 Y 坐标估算索引
    // 实际应用中可能需要更精确的计算
    final itemHeight = 72.0; // 假设每个项目高度
    final index = (localPosition.dy / itemHeight).floor();
    
    return index.clamp(0, _items.length);
  }
  
  @override
  void dispose() {
    _stopAutoScroll();
    super.dispose();
  }
}
