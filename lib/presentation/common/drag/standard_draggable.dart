import 'package:flutter/material.dart';
import '../../../core/constants/drag_constants.dart';
import '../../../core/theme/drag_theme.dart';

/// 标准拖拽组件
/// 
/// 封装 Draggable/LongPressDraggable，提供统一的视觉反馈效果
/// 确保 Tasks 和 Inbox 页面的拖拽外观完全一致
class StandardDraggable<T extends Object> extends StatelessWidget {
  const StandardDraggable({
    required this.child,
    required this.data,
    this.handle,
    this.onDragStarted,
    this.onDragUpdate,
    this.onDragEnd,
    this.enabled = true,
    this.useLongPress = true,
    this.childWhenDraggingOpacity, // 新增：允许自定义 childWhenDragging 的透明度
    super.key,
  });

  final Widget child;
  final T data;
  final Widget? handle; // 可选拖拽手柄
  final VoidCallback? onDragStarted;
  final void Function(DragUpdateDetails)? onDragUpdate;
  final VoidCallback? onDragEnd;
  final bool enabled;
  final bool useLongPress; // 新增：是否使用长按拖拽
  final double? childWhenDraggingOpacity; // 新增参数

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final dragTheme = DragTheme.of(context);
    final content = handle != null ? _withHandle(child, handle!) : child;
    
    final feedback = _buildFeedback(context, dragTheme, content);
    final childWhenDragging = Opacity(
      opacity: childWhenDraggingOpacity ?? DragConstants.draggingOpacity, // 使用自定义值或默认值
      child: content,
    );
    
    final onDragStartedWithLog = () {
      onDragStarted?.call();
    };
    
    final onDragUpdateWithLog = (DragUpdateDetails details) {
      onDragUpdate?.call(details);
    };
    
    final onDragEndWithLog = (DraggableDetails details) {
      onDragEnd?.call();
    };
    
    // 使用立即拖拽或长按拖拽
    if (useLongPress) {
      return LongPressDraggable<T>(
        data: data,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStartedWithLog,
        onDragUpdate: onDragUpdateWithLog,
        onDragEnd: onDragEndWithLog,
        child: content,
      );
    } else {
      return Draggable<T>(
        data: data,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStartedWithLog,
        onDragUpdate: onDragUpdateWithLog,
        onDragEnd: onDragEndWithLog,
        child: content,
      );
    }
  }

  Widget _buildFeedback(BuildContext context, DragTheme theme, Widget content) {
    return Transform.rotate(
      angle: DragConstants.tiltAngle,
      child: Transform.scale(
        scale: DragConstants.feedbackScale,
        child: Material(
          elevation: DragConstants.feedbackElevation,
          borderRadius: BorderRadius.circular(8),
          shadowColor: theme.shadowColor.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(DragConstants.feedbackPadding),
            child: Opacity(
              opacity: DragConstants.feedbackOpacity,
              child: SizedBox(
                width: DragConstants.feedbackWidth,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _withHandle(Widget child, Widget handle) {
    return Row(
      children: [
        handle,
        Expanded(child: child),
      ],
    );
  }
}
