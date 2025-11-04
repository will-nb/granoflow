import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_list_config.dart';

/// 边缘自动滚动接口
///
/// 定义拖拽 Notifier 需要实现的自动滚动方法
abstract class DragNotifierWithAutoScroll {
  /// 开始边缘自动滚动
  ///
  /// [direction] 滚动方向：正数向下，负数向上
  /// [speed] 滚动速度（像素/次），默认 30px
  void startAutoScroll(double direction, {double speed = 30.0});

  /// 停止边缘自动滚动
  void stopAutoScroll();

  /// 设置滚动控制器
  void setScrollController(ScrollController? controller);
}

/// 任务列表边缘自动滚动工具类
///
/// 职责：检测拖拽位置，触发边缘自动滚动
/// - 当拖拽接近屏幕顶部或底部时，自动滚动列表
/// - 通过 TaskListConfig 获取 dragNotifier
/// - 适用于 Inbox 和 Tasks 页面
class TaskListEdgeAutoScroll {
  TaskListEdgeAutoScroll._();

  /// 处理边缘自动滚动
  ///
  /// 当拖拽接近屏幕顶部或底部时，自动滚动列表
  /// - 接近顶部（距离 < 120px）：向上滚动
  /// - 接近底部（距离 < 120px）：向下滚动
  /// - 滚动速度根据距离边缘的距离动态调整（越近越快，最大 30px/次）
  ///
  /// [context] BuildContext（用于获取屏幕尺寸）
  /// [globalPosition] 当前拖拽位置（全局坐标）
  /// [config] 任务列表配置（用于获取 dragNotifier）
  /// [ref] WidgetRef
  static void handleEdgeAutoScroll(
    BuildContext context,
    Offset globalPosition,
    TaskListConfig config,
    WidgetRef ref,
  ) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 获取拖拽 Notifier
    final dragNotifier = config.getDragNotifier(ref);
    if (dragNotifier is! DragNotifierWithAutoScroll) {
      // 如果 Notifier 不支持自动滚动，直接返回
      return;
    }

    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    // 边缘触发阈值：120px
    const edgeThreshold = 120.0;
    // 最大滚动速度：30px/次
    const maxScrollSpeed = 30.0;

    // 关键修复：将检测位置限制在屏幕范围内
    // 即使拖拽位置超出屏幕，也使用屏幕边界位置进行检测
    final clampedY = globalPosition.dy.clamp(0.0, screenHeight);

    // 检测是否完全超出屏幕边界
    final isAboveScreen = globalPosition.dy < 0;
    final isBelowScreen = globalPosition.dy > screenHeight;

    // 使用限制后的位置计算距离屏幕顶部和底部的距离
    final distanceFromTop = clampedY;
    final distanceFromBottom = screenHeight - clampedY;

    // 检测是否接近顶部或底部（包括超出边界的情况）
    if (distanceFromTop < edgeThreshold || isAboveScreen) {
      // 接近顶部或已拖出顶部：向上滚动
      // 如果已拖出屏幕，使用最大速度
      // 如果还在边缘区域，根据距离计算速度
      final speedFactor = isAboveScreen
          ? 1.0 // 完全超出顶部，使用最大速度
          : (edgeThreshold - distanceFromTop) / edgeThreshold;
      final scrollSpeed = maxScrollSpeed * speedFactor;

      dragNotifier.startAutoScroll(-1.0, speed: scrollSpeed);

      if (kDebugMode) {
        debugPrint(
          '[AutoScroll] {event: start, direction: up, originalY: ${globalPosition.dy.toStringAsFixed(1)}, clampedY: ${clampedY.toStringAsFixed(1)}, isAboveScreen: $isAboveScreen, speed: ${scrollSpeed.toStringAsFixed(1)}}',
        );
      }
    } else if (distanceFromBottom < edgeThreshold || isBelowScreen) {
      // 接近底部或已拖出底部：向下滚动
      // 如果已拖出屏幕，使用最大速度
      // 如果还在边缘区域，根据距离计算速度
      final speedFactor = isBelowScreen
          ? 1.0 // 完全超出底部，使用最大速度
          : (edgeThreshold - distanceFromBottom) / edgeThreshold;
      final scrollSpeed = maxScrollSpeed * speedFactor;

      dragNotifier.startAutoScroll(1.0, speed: scrollSpeed);

      if (kDebugMode) {
        debugPrint(
          '[AutoScroll] {event: start, direction: down, originalY: ${globalPosition.dy.toStringAsFixed(1)}, clampedY: ${clampedY.toStringAsFixed(1)}, isBelowScreen: $isBelowScreen, speed: ${scrollSpeed.toStringAsFixed(1)}}',
        );
      }
    } else {
      // 远离边缘：停止滚动
      dragNotifier.stopAutoScroll();
    }
  }
}

