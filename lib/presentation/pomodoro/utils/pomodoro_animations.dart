import 'package:flutter/material.dart';

/// 番茄时钟动画工具
/// 
/// 提供页面进入、完成庆祝、背景呼吸等动画
class PomodoroAnimations {
  const PomodoroAnimations._();

  /// 页面进入动画
  /// 
  /// 从中心淡入并放大
  static Animation<double> createPageEnterAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  /// 完成庆祝动画
  /// 
  /// 从中心放大并淡出
  static Animation<double> createCompletionAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  /// 背景呼吸动画
  /// 
  /// 渐变背景的呼吸效果（轻微缩放）
  static Animation<double> createBackgroundBreathingAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  /// 创建呼吸动画控制器
  /// 
  /// 持续循环的呼吸动画
  static AnimationController createBreathingController(TickerProvider vsync) {
    final controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    );
    controller.repeat(reverse: true);
    return controller;
  }
}

