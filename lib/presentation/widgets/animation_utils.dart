import 'package:flutter/material.dart';

/// 动画工具类
/// 
/// 提供通用的动画工具函数，用于创建 FadeTransition + SlideTransition 动画
/// 可在多个地方复用，保持动画效果的一致性
class AnimationUtils {
  const AnimationUtils._();

  /// 创建淡入滑动过渡动画
  /// 
  /// [child] - 要应用动画的子组件
  /// [animation] - 动画对象（通常来自 AnimatedSwitcher 等）
  /// [begin] - 滑动起始位置（默认 Offset(0, -0.1)，向上滑动）
  /// [end] - 滑动结束位置（默认 Offset.zero）
  /// 
  /// 返回：FadeTransition + SlideTransition 组合的 Widget
  static Widget createFadeSlideTransition(
    Widget child,
    Animation<double> animation, {
    Offset begin = const Offset(0, -0.1),
    Offset end = Offset.zero,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

