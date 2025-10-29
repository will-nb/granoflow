import 'package:flutter/material.dart';
import '../../core/constants/drag_constants.dart';

/// 通用的 ReorderableListView proxyDecorator
/// 
/// 提供统一的拖拽视觉反馈：
/// - 倾斜角度（iOS Reminders 风格）
/// - 缩放效果
/// - 半透明 + 强阴影
/// 
/// 使用方式：
/// ```dart
/// ReorderableListView.builder(
///   proxyDecorator: ReorderableProxyDecorator.build,
///   ...
/// )
/// ```
class ReorderableProxyDecorator {
  /// 构建拖拽时的视觉装饰
  /// 
  /// [child] - 被拖拽的子组件
  /// [index] - 子组件在列表中的索引
  /// [animation] - 拖拽动画（0.0 到 1.0）
  static Widget build(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 使用 DragConstants 中定义的常量
        final tiltAngle = DragConstants.tiltAngle; // ~1.5度
        final feedbackScale = DragConstants.feedbackScale; // 轻微放大
        final feedbackOpacity = DragConstants.feedbackOpacity; // 半透明
        final feedbackElevation = DragConstants.feedbackElevation; // 强阴影
        final theme = Theme.of(context);
        
        return Transform.rotate(
          angle: tiltAngle * animation.value,
          child: Transform.scale(
            scale: 1.0 + ((feedbackScale - 1.0) * animation.value),
            child: Opacity(
              opacity: feedbackOpacity,
              child: Material(
                elevation: feedbackElevation * animation.value,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
