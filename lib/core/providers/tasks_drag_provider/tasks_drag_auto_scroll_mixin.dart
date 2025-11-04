import 'dart:async';
import 'package:flutter/material.dart';

/// 拖拽自动滚动 mixin
/// 提供边缘自动滚动功能
mixin TasksDragAutoScrollMixin {
  /// 是否正在自动滚动
  bool _isAutoScrolling = false;
  
  /// 自动滚动定时器（用于持续滚动）
  Timer? _autoScrollTimer;
  
  /// 当前滚动控制器（需要在外部设置）
  ScrollController? _scrollController;
  
  /// 拖拽开始时的滚动位置（用于拖拽结束后恢复）
  double? _scrollPositionBeforeDrag;

  /// 设置滚动控制器
  void setScrollController(ScrollController? controller) {
    _scrollController = controller;
  }

  /// 保存拖拽开始时的滚动位置
  void saveScrollPositionBeforeDrag() {
    if (_scrollController != null && _scrollController!.hasClients) {
      _scrollPositionBeforeDrag = _scrollController!.position.pixels;
    }
  }

  /// 获取拖拽开始时的滚动位置
  double? get scrollPositionBeforeDrag => _scrollPositionBeforeDrag;

  /// 清除拖拽开始时的滚动位置
  void clearScrollPositionBeforeDrag() {
    _scrollPositionBeforeDrag = null;
  }

  /// 获取滚动控制器
  ScrollController? get scrollController => _scrollController;

  /// 开始边缘自动滚动
  /// 
  /// [direction] 滚动方向：正数向下，负数向上
  /// [speed] 滚动速度（像素/次），默认 30px
  void startAutoScroll(double direction, {double speed = 30.0}) {
    if (_isAutoScrolling && _scrollController != null && _scrollController!.hasClients) {
      // 已经在滚动，更新方向
      _updateAutoScroll(direction, speed);
      return;
    }
    
    if (_scrollController == null || !_scrollController!.hasClients) {
      return; // 没有有效的滚动控制器
    }
    
    _isAutoScrolling = true;
    _updateAutoScroll(direction, speed);
  }
  
  /// 更新自动滚动
  void _updateAutoScroll(double direction, double speed) {
    _autoScrollTimer?.cancel();
    
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController == null || !_scrollController!.hasClients) {
        stopAutoScroll();
        return;
      }
      
      final scrollPosition = _scrollController!.position;
      final currentOffset = scrollPosition.pixels;
      final maxScroll = scrollPosition.maxScrollExtent;
      final minScroll = scrollPosition.minScrollExtent;
      
      // 计算新位置
      double newOffset = currentOffset + (direction * speed);
      
      // 限制在边界内（但不停止滚动，由检测逻辑统一决定停止）
      if (newOffset < minScroll) {
        newOffset = minScroll;
      } else if (newOffset > maxScroll) {
        newOffset = maxScroll;
      }
      
      // 执行滚动（即使到达边界也执行，确保位置被正确限制）
      // 只在位置变化时执行，避免无效调用
      if (currentOffset != newOffset) {
        _scrollController!.jumpTo(newOffset);
      }
      // 定时器继续运行，等待下一次检测逻辑的决策
    });
  }
  
  /// 停止边缘自动滚动
  void stopAutoScroll() {
    _isAutoScrolling = false;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  /// 恢复拖拽开始时的滚动位置
  void restoreScrollPosition() {
    final savedScrollPosition = _scrollPositionBeforeDrag;
    if (savedScrollPosition != null && _scrollController != null && _scrollController!.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController != null && _scrollController!.hasClients) {
          // 使用 jumpTo 而不是 animateTo，避免动画干扰用户
          final maxScroll = _scrollController!.position.maxScrollExtent;
          final minScroll = _scrollController!.position.minScrollExtent;
          final targetPosition = savedScrollPosition.clamp(minScroll, maxScroll);
          _scrollController!.jumpTo(targetPosition);
        }
      });
    }
  }
}

