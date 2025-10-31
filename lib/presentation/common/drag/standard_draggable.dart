import 'package:flutter/material.dart';
import '../../../core/constants/drag_constants.dart';
import '../../../core/theme/drag_theme.dart';

/// 标准拖拽组件
/// 
/// 封装 LongPressDraggable，提供统一的视觉反馈效果
/// 确保 Tasks 和 Inbox 页面的拖拽外观完全一致
class StandardDraggable<T extends Object> extends StatelessWidget {
  const StandardDraggable({
    required this.child,
    required this.data,
    this.handle,
    this.onDragStarted,
    this.onDragEnd,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final T data;
  final Widget? handle; // 可选拖拽手柄
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final dragTheme = DragTheme.of(context);
    final content = handle != null ? _withHandle(child, handle!) : child;
    
    return LongPressDraggable<T>(
      data: data,
      dragAnchorStrategy: childDragAnchorStrategy,
      feedback: _buildFeedback(context, dragTheme, content),
      childWhenDragging: Opacity(
        opacity: DragConstants.draggingOpacity,
        child: content,
      ),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd?.call(),
      child: content,
    );
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
          child: Opacity(
            opacity: DragConstants.feedbackOpacity,
            child: SizedBox(
              width: DragConstants.feedbackWidth,
              child: content,
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
