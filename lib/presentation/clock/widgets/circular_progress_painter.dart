import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/ocean_breeze_color_schemes.dart';

/// 环形进度条绘制器
/// 
/// 支持正常状态（顺时针填充）和超时状态（逆时针填充）
class CircularProgressPainter extends CustomPainter {
  CircularProgressPainter({
    required this.progress,
    required this.isOvertime,
    required this.isWarning,
    required this.strokeWidth,
    required this.errorColor,
    this.animation,
    this.customColor,
  }) : super(repaint: animation);

  /// 进度值（0.0 - 1.0）
  /// 正常状态：0.0（未开始）到 1.0（完成）
  /// 超时状态：0.0（刚好完成）到 1.0（超时百分比）
  final double progress;
  
  /// 是否超时
  final bool isOvertime;
  
  /// 是否警告状态（< 5分钟）
  final bool isWarning;
  
  /// 线条宽度
  final double strokeWidth;
  
  /// 错误颜色（超时状态使用）
  final Color errorColor;
  
  /// 自定义颜色（如果提供，优先使用此颜色，忽略状态判断）
  final Color? customColor;
  
  /// 动画控制器（用于动画效果）
  final Animation<double>? animation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2);
    
    // 先绘制背景圆环（白色底色）
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)  // 提高不透明度，使圆环更清晰
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // 绘制完整的背景圆环（360度）
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // 确定进度条颜色
    final color = _getProgressColor();
    
    // 创建进度条画笔
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // 根据状态确定绘制方式
    if (isOvertime) {
      _drawOvertimeProgress(canvas, center, radius, paint);
    } else {
      _drawNormalProgress(canvas, center, radius, paint);
    }
  }

  /// 获取进度条颜色
  Color _getProgressColor() {
    // 如果提供了自定义颜色，优先使用
    if (customColor != null) {
      return customColor!;
    }
    
    if (isOvertime) {
      // 超时状态：使用 error 色
      return errorColor;
    } else if (isWarning) {
      // 警告状态（< 5分钟）：橙色
      return OceanBreezeColorSchemes.clockPrimaryOrange;
    } else {
      // 正常状态：海盐蓝
      return OceanBreezeColorSchemes.seaSaltBlue;
    }
  }

  /// 绘制正常状态进度（顺时针）
  void _drawNormalProgress(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    // 从顶部（-90度）开始，顺时针绘制
    const startAngle = -math.pi / 2; // -90度
    final sweepAngle = 2 * math.pi * progress; // 进度对应的角度
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false, // 不填充中心
      paint,
    );
  }

  /// 绘制超时状态进度（逆时针）
  void _drawOvertimeProgress(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    // 从顶部（-90度）开始，逆时针绘制
    const startAngle = -math.pi / 2; // -90度
    final sweepAngle = -2 * math.pi * progress; // 负角度表示逆时针
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false, // 不填充中心
      paint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isOvertime != isOvertime ||
        oldDelegate.isWarning != isWarning ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.errorColor != errorColor ||
        oldDelegate.customColor != customColor ||
        oldDelegate.animation != animation;
  }
}

