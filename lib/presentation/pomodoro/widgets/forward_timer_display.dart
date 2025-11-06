import 'package:flutter/material.dart';

import '../utils/pomodoro_timer_utils.dart';

/// 正向计时显示组件
/// 
/// 显示大号 HH:MM:SS 格式的正向计时
/// 根据屏幕宽度自适应大小，窗口大小改变时自动调整，且不会折行
class ForwardTimerDisplay extends StatelessWidget {
  const ForwardTimerDisplay({
    super.key,
    required this.elapsedTime,
    this.fontSize,
  });

  /// 已过时间
  final Duration elapsedTime;
  
  /// 字体大小（可选，默认根据屏幕大小自适应）
  /// 注意：实际显示的字体大小由 FittedBox 根据可用宽度自动缩放
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final formattedTime = PomodoroTimerUtils.formatElapsedTime(elapsedTime);
    
    // 使用 LayoutBuilder 获取可用宽度，确保响应窗口大小变化
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕大小确定基础字体大小
        final screenSize = MediaQuery.of(context).size;
        final baseFontSize = fontSize ?? _getResponsiveFontSize(screenSize);
        
        // 使用 FittedBox 自动缩放文本以适应可用宽度
        // BoxFit.scaleDown 确保文本只会缩小，不会放大超过基础大小
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Text(
            formattedTime,
            style: TextStyle(
              fontSize: baseFontSize,
              fontFamily: 'monospace', // 等宽数字字体
              fontWeight: FontWeight.bold,
              color: Colors.white, // 白色，高对比度
              shadows: [
                // 发光效果
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                // 阴影效果
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            maxLines: 1, // 确保不会折行
            overflow: TextOverflow.visible, // 允许文本溢出（由 FittedBox 处理缩放）
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  /// 根据屏幕大小获取响应式字体大小
  /// 这个值作为基础大小，FittedBox 会根据可用宽度自动缩放
  double _getResponsiveFontSize(Size screenSize) {
    final width = screenSize.width;
    if (width < 600) {
      // 手机：80sp
      return 80;
    } else if (width < 1024) {
      // 平板：100sp
      return 100;
    } else {
      // 桌面：120sp
      return 120;
    }
  }
}

