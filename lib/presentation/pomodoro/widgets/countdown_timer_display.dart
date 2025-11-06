import 'package:flutter/material.dart';

import '../../../core/theme/ocean_breeze_color_schemes.dart';
import '../utils/pomodoro_timer_utils.dart';
import 'circular_progress_painter.dart';

/// 倒计时显示组件
/// 
/// 显示小号倒计时和环形进度条
class CountdownTimerDisplay extends StatelessWidget {
  const CountdownTimerDisplay({
    super.key,
    required this.countdownRemaining,
    required this.originalDuration,
    required this.isOvertime,
    this.size = 200,
    this.strokeWidth = 8,
  });

  /// 倒计时剩余时间（可能为负数表示超时）
  final Duration countdownRemaining;
  
  /// 原始倒计时时长（用于计算进度）
  final Duration originalDuration;
  
  /// 是否超时
  final bool isOvertime;
  
  /// 环形大小（直径）
  final double size;
  
  /// 线条宽度
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    // 计算进度
    final progress = _calculateProgress();
    
    // 确定是否警告状态（< 5分钟且未超时）
    final isWarning = !isOvertime && 
        countdownRemaining.inMinutes < 5 && 
        countdownRemaining.inMinutes >= 0;
    
    // 获取响应式字体大小
    final fontSize = _getResponsiveFontSize(screenSize);
    
    // 格式化倒计时时间
    final formattedTime = PomodoroTimerUtils.formatCountdown(countdownRemaining);
    
    // 确定文字颜色
    final textColor = _getTextColor(context, isOvertime, isWarning);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 环形进度条
          CustomPaint(
            size: Size(size, size),
            painter: CircularProgressPainter(
              progress: progress,
              isOvertime: isOvertime,
              isWarning: isWarning,
              strokeWidth: strokeWidth,
              errorColor: theme.colorScheme.error,
            ),
          ),
          // 倒计时数字
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'monospace', // 等宽数字字体
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 计算进度值（0.0 - 1.0）
  double _calculateProgress() {
    if (originalDuration.inSeconds <= 0) {
      return 0.0;
    }
    
    if (isOvertime) {
      // 超时状态：计算超时百分比
      // countdownRemaining 在超时时是负数，需要取绝对值
      return PomodoroTimerUtils.calculateOvertimePercentage(
        overtimeSeconds: countdownRemaining.inSeconds.abs(),
        originalDurationSeconds: originalDuration.inSeconds,
      );
    } else {
      // 正常状态：计算剩余百分比
      final elapsed = originalDuration - countdownRemaining;
      final progress = elapsed.inSeconds / originalDuration.inSeconds;
      return progress.clamp(0.0, 1.0);
    }
  }

  /// 根据屏幕大小获取响应式字体大小
  double _getResponsiveFontSize(Size screenSize) {
    final width = screenSize.width;
    if (width < 600) {
      // 手机：40sp
      return 40;
    } else if (width < 1024) {
      // 平板：50sp
      return 50;
    } else {
      // 桌面：60sp
      return 60;
    }
  }

  /// 获取文字颜色
  Color _getTextColor(BuildContext context, bool isOvertime, bool isWarning) {
    if (isOvertime) {
      // 超时状态：error 色
      return Theme.of(context).colorScheme.error;
    } else if (isWarning) {
      // 警告状态（< 5分钟）：橙色
      return OceanBreezeColorSchemes.pomodoroVibrantOrange;
    } else {
      // 正常状态：海盐蓝
      return OceanBreezeColorSchemes.seaSaltBlue;
    }
  }
}

