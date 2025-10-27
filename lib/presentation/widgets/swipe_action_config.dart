import 'package:flutter/material.dart';
import 'swipe_action_type.dart';

/// 滑动动作配置类
/// 
/// 定义了滑动组件的配置选项，包括左右滑动动作、提示文字键、图标和颜色
class SwipeActionConfig {
  /// 左滑动作类型
  final SwipeActionType leftAction;
  
  /// 右滑动作类型
  final SwipeActionType rightAction;
  
  /// 左滑提示文字键（用于本地化）
  final String leftHintKey;
  
  /// 右滑提示文字键（用于本地化）
  final String rightHintKey;
  
  /// 左滑图标
  final IconData leftIcon;
  
  /// 右滑图标
  final IconData rightIcon;
  
  /// 左滑背景颜色
  final Color leftColor;
  
  /// 右滑背景颜色
  final Color rightColor;

  const SwipeActionConfig({
    required this.leftAction,
    required this.rightAction,
    required this.leftHintKey,
    required this.rightHintKey,
    required this.leftIcon,
    required this.rightIcon,
    required this.leftColor,
    required this.rightColor,
  });
}
