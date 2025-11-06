import 'package:flutter/material.dart';

import '../../../core/theme/ocean_breeze_color_schemes.dart';
import 'circular_progress_painter.dart';

@Deprecated('请迁移到 CompactTimerSlider，未来版本将移除此组件。')
/// 正向计时环形显示组件
/// 
/// 使用环形进度条特效展示正向计时
/// 每一圈代表1小时（60分钟），每圈完成后自动切换颜色
/// 显示格式：HH:MM（小时和分钟，不显示秒）
/// 圆环大小根据屏幕宽度自动计算，使用审美比例优化
class ForwardTimerCircularDisplay extends StatelessWidget {
  const ForwardTimerCircularDisplay({
    super.key,
    required this.elapsedTime,
    this.size,
    this.strokeWidth,
  });

  /// 已过时间
  final Duration elapsedTime;
  
  /// 环形大小（直径，可选，如果为 null 则根据屏幕自动计算）
  final double? size;
  
  /// 线条宽度（可选，如果为 null 则根据圆环大小自动计算）
  final double? strokeWidth;

  /// 颜色列表（循环使用）
  static const List<Color> _colorList = [
    OceanBreezeColorSchemes.seaSaltBlue,           // 第0圈：海盐蓝
    OceanBreezeColorSchemes.mintCyan,              // 第1圈：薄荷青
    OceanBreezeColorSchemes.lakeCyan,              // 第2圈：湖光青
    OceanBreezeColorSchemes.pomodoroVibrantOrange, // 第3圈：活力橙
    OceanBreezeColorSchemes.pomodoroSuccessGreen,  // 第4圈：成功绿
  ];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // 计算当前小时（圈数）
    final hours = elapsedTime.inHours;
    
    // 计算当前圈的进度（0.0 - 1.0）
    final currentHourMinutes = elapsedTime.inMinutes % 60;
    final progress = currentHourMinutes / 60.0;
    
    // 根据小时数选择颜色（循环使用）
    final colorIndex = hours % _colorList.length;
    final progressColor = _colorList[colorIndex];
    
    // 计算圆环大小（基于屏幕宽度，使用黄金比例相关的比例）
    // 如果传入了自定义的 size，则使用传入的值
    final circleSize = size ?? _calculateCircleSize(screenSize);
    
    // 根据圆环大小计算字体大小（字体约等于圆环直径的 1/3.5）
    final fontSize = circleSize / 3.5;
    
    // 根据圆环大小计算线条宽度（线条宽度约等于圆环直径的 4%）
    // 如果传入了自定义的 strokeWidth，则使用传入的值
    final finalStrokeWidth = strokeWidth ?? (circleSize * 0.04);
    
    // 显示 HH:MM 格式（不显示秒）
    final displayHours = elapsedTime.inHours;
    final displayMinutes = elapsedTime.inMinutes.remainder(60);
    final displayText = '${displayHours.toString().padLeft(2, '0')}:'
                       '${displayMinutes.toString().padLeft(2, '0')}';
    
    return SizedBox(
      width: circleSize,
      height: circleSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 环形进度条
          CustomPaint(
            size: Size(circleSize, circleSize),
            painter: CircularProgressPainter(
              progress: progress,
              isOvertime: false, // 正向计时不使用超时状态
              isWarning: false,  // 不使用警告状态
              strokeWidth: finalStrokeWidth,
              errorColor: Theme.of(context).colorScheme.error,
              customColor: progressColor, // 使用自定义颜色
            ),
          ),
          // 时间数字
          Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'monospace', // 等宽数字字体
              fontWeight: FontWeight.w500,
              color: progressColor, // 使用与进度条相同的颜色
            ),
          ),
        ],
      ),
    );
  }

  /// 根据屏幕大小计算圆环直径
  /// 使用审美原理：圆环直径约为屏幕宽度的 55%，但设置合理的最大值
  double _calculateCircleSize(Size screenSize) {
    final width = screenSize.width;
    final calculatedSize = width * 0.55;
    
    // 设置合理的最大值，避免在大屏幕上过大
    if (width < 600) {
      // 手机：最大 280px
      return calculatedSize.clamp(200, 280);
    } else if (width < 1024) {
      // 平板：最大 400px
      return calculatedSize.clamp(300, 400);
    } else {
      // 桌面：最大 500px
      return calculatedSize.clamp(400, 500);
    }
  }
}

