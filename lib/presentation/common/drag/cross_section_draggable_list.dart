import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/drag_constants.dart';
import 'draggable_list_controller.dart';
import 'draggable_list_delegate.dart';
import 'standard_draggable.dart';
import 'standard_drag_target.dart';

/// 跨区域拖拽列表组件
/// 
/// 支持：
/// - 列表内项目重排序
/// - 跨区域拖拽（接收外部项目）
/// - 项目成为其他项目的子项
/// - 子项提升为根项
class CrossSectionDraggableList<T extends Object> extends ConsumerStatefulWidget {
  const CrossSectionDraggableList({
    super.key,
    required this.items,
    required this.delegate,
    required this.controller,
    required this.sectionId,
    this.padding,
    this.physics,
    this.shrinkWrap = true,
    this.showPromoteTarget = false,
    this.dragStateProvider,
    this.useLongPressDrag = false,  // 改为默认使用立即拖拽
  });
  
  /// 列表项数据
  final List<T> items;
  
  /// 行为委托
  final DraggableListDelegate<T> delegate;
  
  /// 列表控制器
  final DraggableListController<T> controller;
  
  /// 区域标识符
  final String sectionId;
  
  /// 列表内边距
  final EdgeInsetsGeometry? padding;
  
  /// 滚动物理特性
  final ScrollPhysics? physics;
  
  /// 是否收缩包裹内容
  final bool shrinkWrap;
  
  /// 是否显示提升为根项的目标区域
  final bool showPromoteTarget;
  
  /// 拖拽状态提供者（可选）
  final StateNotifierProvider<dynamic, dynamic>? dragStateProvider;
  
  final bool useLongPressDrag;  // 新增：控制拖拽类型

  @override
  ConsumerState<CrossSectionDraggableList<T>> createState() => 
      _CrossSectionDraggableListState<T>();
}

class _CrossSectionDraggableListState<T extends Object> extends ConsumerState<CrossSectionDraggableList<T>> 
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('[CrossSectionDraggableList] initState - sectionId=${widget.sectionId}, items.length=${widget.items.length}');
    }
    _scrollController = ScrollController();
    widget.controller.setScrollController(_scrollController);
    
    // CRITICAL FIX: Defer controller initialization to avoid Riverpod error
    // 
    // Problem: Calling controller.initItems() directly in initState() triggers
    // Riverpod's "Tried to modify a provider while the widget tree was building" error
    // because the controller is a ChangeNotifier managed by ChangeNotifierProvider.
    // Modifying it during initState (which is part of the build phase) is forbidden.
    // 
    // Why not Future.microtask?: microtask executes before the first frame completes,
    // which is still considered part of the build phase by Riverpod's safety checks.
    // 
    // Solution: Use addPostFrameCallback to defer initialization until after the
    // first frame is completely rendered. This ensures we're not modifying the
    // provider during any part of the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (kDebugMode) {
          debugPrint('[CrossSectionDraggableList] PostFrameCallback - 初始化 items, sectionId=${widget.sectionId}, items.length=${widget.items.length}');
        }
        widget.controller.initItems(widget.items);
      }
    });
  }
  
  @override
  void didUpdateWidget(CrossSectionDraggableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // CRITICAL FIX: Defer controller update to avoid Riverpod error
    // 
    // Problem: didUpdateWidget is part of the widget lifecycle (similar to build,
    // initState, dispose). Calling controller.updateItems() here directly triggers
    // notifyListeners(), which violates Riverpod's rule against modifying providers
    // during the widget tree building phase.
    // 
    // This causes the error: "Tried to modify a provider while the widget tree was building"
    // 
    // Why this happens:
    // 1. User drags and reorders a task
    // 2. Database updates successfully
    // 3. Repository emits new data via Stream
    // 4. Widget receives new items via didUpdateWidget
    // 5. controller.updateItems() triggers notifyListeners()
    // 6. Error: We're still in the build phase!
    // 
    // Solution: Use addPostFrameCallback to defer the update until after the current
    // frame is completely rendered. This ensures we're not modifying the provider
    // during the build phase.
    if (oldWidget.items != widget.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.controller.updateItems(widget.items);
        }
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 顶部提升目标区域
        if (widget.showPromoteTarget)
          widget.delegate.buildPromoteTarget(context) ?? const SizedBox.shrink(),
          
        // CRITICAL FIX: Use widget.items instead of controller.items for AnimatedList
        // 
        // Problem: The original code used `widget.controller.items.length` for initialItemCount.
        // However, controller.items is EMPTY ([]) at widget creation time because
        // controller.initItems() is deferred to addPostFrameCallback (see initState above).
        // This caused AnimatedList to be created with initialItemCount=0, meaning
        // itemBuilder would NEVER be called, resulting in an empty list display!
        // 
        // Timeline of the bug:
        // 1. initState(): controller.items = [] (empty, not initialized yet)
        // 2. build(): AnimatedList created with initialItemCount = controller.items.length = 0
        // 3. addPostFrameCallback(): controller.initItems() populates controller.items
        // 4. Problem: AnimatedList already created with initialItemCount=0, won't rebuild!
        // 5. Result: itemBuilder never called → empty screen with only drag targets visible
        // 
        // Solution: Use widget.items.length directly. widget.items is immediately available
        // and contains the actual data, ensuring AnimatedList is created with the correct
        // item count from the start. The controller will be populated later via
        // addPostFrameCallback, but AnimatedList will already know how many items to render.
        AnimatedList(
          key: widget.controller.listKey,
          initialItemCount: widget.items.length,  // Use widget.items, NOT controller.items
          controller: _scrollController,
          padding: widget.padding,
          physics: widget.physics,
          shrinkWrap: widget.shrinkWrap,
          itemBuilder: (context, index, animation) {
            if (kDebugMode) {
              debugPrint('[CrossSectionDraggableList] itemBuilder called - sectionId=${widget.sectionId}, index=$index, items.length=${widget.controller.items.length}');
            }
            
            // CRITICAL: Use widget.items for data access, not controller.items
            // 
            // Reason: During initial build, controller.items is empty because initItems()
            // hasn't been called yet (deferred to addPostFrameCallback). To access the
            // actual data during itemBuilder, we must use widget.items.
            // 
            // Note: After initialization, controller.items will match widget.items, but
            // for consistency and correctness during the initial render, always use
            // widget.items in itemBuilder.
            if (index >= widget.items.length) {
              if (kDebugMode) {
                debugPrint('[CrossSectionDraggableList] 越界 - index=$index >= items.length=${widget.items.length}');
              }
              return const SizedBox.shrink();
            }
            
            final item = widget.items[index];  // Use widget.items, NOT controller.items
            if (kDebugMode) {
              debugPrint('[CrossSectionDraggableList] 构建项目 - index=$index, itemId=${widget.delegate.getItemId(item)}');
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部插入目标（第一个项目之前）
                if (index == 0)
                  _buildInsertionTarget(0),
                  
                // 可拖拽的项目
                _buildDraggableItem(item, index, animation),
                
                // 底部插入目标（每个项目之后）
                _buildInsertionTarget(index + 1),
              ],
            );
          },
        ),
      ],
    );
  }
  
  /// 构建可拖拽的项目
  Widget _buildDraggableItem(T item, int index, Animation<double> animation) {
    final itemId = widget.delegate.getItemId(item);
    final isDragging = widget.controller.isDragging && 
                      widget.controller.draggedIndex == index;
    
    if (kDebugMode) {
      debugPrint('[DragList] Building draggable item - index: $index, itemId: $itemId, isDragging: $isDragging');
    }
    
    return StandardDraggable<T>(
      key: ValueKey(itemId),
      data: item,
      enabled: true,
      useLongPress: widget.useLongPressDrag,  // 传递拖拽类型
      onDragStarted: () => _onDragStarted(item, index),
      onDragEnd: () => _onDragEnd(),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, child) {
          // 如果正在拖拽此项目，显示占位符
          if (isDragging) {
            return Opacity(
              opacity: DragConstants.draggingOpacity,
              child: child,
            );
          }
          
          // 检查是否可以成为子项目
          return DragTarget<T>(
            onWillAcceptWithDetails: (details) {
              return widget.delegate.canMakeChild(details.data, item);
            },
            onAcceptWithDetails: (details) async {
              await widget.delegate.onMakeChild(details.data, item);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isHovering 
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: child,
              );
            },
          );
        },
        child: widget.delegate.buildItem(context, item, index, animation),
      ),
    );
  }
  
  /// 构建插入目标线
  Widget _buildInsertionTarget(int index) {
    return StandardDragTarget<T>(
      type: index == 0 ? InsertionType.first : InsertionType.between,
      showWhenIdle: false,
      canAccept: (dragged) {
        // 不能拖拽到自己的位置
        if (widget.controller.draggedItem != null &&
            widget.delegate.getItemId(dragged) == 
            widget.delegate.getItemId(widget.controller.draggedItem as T)) {
          final dragIndex = widget.controller.draggedIndex!;
          if (index == dragIndex || index == dragIndex + 1) {
            return false;
          }
        }
        
        // 检查是否可以接收外部项目
        return widget.delegate.canAcceptExternal(dragged, index);
      },
      onAccept: (dragged) async {
        // 如果是同列表内的项目，执行重排序
        if (widget.controller.draggedItem != null &&
            widget.delegate.getItemId(dragged) == 
            widget.delegate.getItemId(widget.controller.draggedItem as T)) {
          final oldIndex = widget.controller.draggedIndex!;
          final newIndex = index > oldIndex ? index - 1 : index;
          
          if (widget.delegate.canReorder(dragged, oldIndex, newIndex)) {
            await widget.delegate.onReorder(dragged, oldIndex, newIndex);
          }
        } else {
          // 外部项目
          await widget.delegate.onAcceptExternal(dragged, index);
        }
      },
      onHoverChanged: (isHovering) {
        if (isHovering) {
          widget.controller.updateHoverIndex(index);
        } else if (widget.controller.hoverIndex == index) {
          widget.controller.updateHoverIndex(null);
        }
      },
    );
  }
  
  /// 开始拖拽
  void _onDragStarted(T item, int index) {
    if (kDebugMode) {
      debugPrint('[DragList] onDragStarted - item: $item, index: $index');
    }
    
    widget.controller.startDrag(item, index);
    
    // 通知拖拽状态提供者（如果有）
    if (widget.dragStateProvider != null) {
      final notifier = ref.read(widget.dragStateProvider!.notifier);
      if (notifier.runtimeType.toString().contains('startDrag')) {
        (notifier as dynamic).startDrag(item);
      }
    }
  }
  
  /// 结束拖拽
  void _onDragEnd() {
    if (kDebugMode) {
      debugPrint('[DragList] onDragEnd - draggedItem: ${widget.controller.draggedItem}, draggedIndex: ${widget.controller.draggedIndex}');
    }
    
    widget.controller.endDrag();
    
    // 通知拖拽状态提供者（如果有）
    if (widget.dragStateProvider != null) {
      final notifier = ref.read(widget.dragStateProvider!.notifier);
      if (notifier.runtimeType.toString().contains('endDrag')) {
        (notifier as dynamic).endDrag();
      }
    }
  }
}
