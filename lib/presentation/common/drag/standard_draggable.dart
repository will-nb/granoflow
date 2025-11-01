import 'package:flutter/foundation.dart';
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
    this.onDragEnd,
    this.enabled = true,
    this.useLongPress = true,  // 新增：控制是否使用长按
    super.key,
  });

  final Widget child;
  final T data;
  final Widget? handle; // 可选拖拽手柄
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final bool enabled;
  final bool useLongPress; // 新增：是否使用长按拖拽

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final dragTheme = DragTheme.of(context);
    final content = handle != null ? _withHandle(child, handle!) : child;
    
    // 记录拖拽类型
    if (kDebugMode) {
      debugPrint('[Drag] Creating ${useLongPress ? "LongPress" : "Immediate"}Draggable for data: $data');
    }
    
    final feedback = _buildFeedback(context, dragTheme, content);
    final childWhenDragging = Opacity(
      opacity: DragConstants.draggingOpacity,
      child: content,
    );
    
    final onDragStartedWithLog = () {
      if (kDebugMode) {
        debugPrint('[Drag] Drag started - data: $data, timestamp: ${DateTime.now().toIso8601String()}');
      }
      onDragStarted?.call();
    };
    
    final onDragEndWithLog = (DraggableDetails details) {
      if (kDebugMode) {
        debugPrint('[Drag] Drag ended - data: $data, '
                  'wasAccepted: ${details.wasAccepted}, '
                  'velocity: ${details.velocity}, '
                  'offset: ${details.offset}, '
                  'timestamp: ${DateTime.now().toIso8601String()}');
      }
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
        onDragEnd: onDragEndWithLog,
        // 添加长按监听以记录日志
        onDragUpdate: (details) {
          if (kDebugMode && details.localPosition.distance < 1) {
            debugPrint('[Drag] Long press detected, waiting for drag threshold...');
          }
        },
        child: content,
      );
    } else {
      return Draggable<T>(
        data: data,
        dragAnchorStrategy: childDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        onDragStarted: onDragStartedWithLog,
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
