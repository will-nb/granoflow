import 'package:flutter/material.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

import '../../../core/theme/ocean_breeze_color_schemes.dart';

/// 紧凑竖屏计时器圆环封装
///
/// 基于 `sleek_circular_slider`，提供统一的尺寸、渐变与文本排版入口，
/// 供竖屏布局直接复用。默认以 60 分钟为一圈，显示 HH:MM 文本。
class CompactTimerSlider extends StatelessWidget {
  const CompactTimerSlider({
    super.key,
    required this.elapsed,
    required this.diameter,
    this.palette = const CompactTimerPalette.normal(),
    this.labelBuilder,
    this.innerBuilder,
  });

  /// 已经过去的时间
  final Duration elapsed;

  /// 圆环直径，由上层根据设备断点 clamp 后传入
  final double diameter;

  /// 颜色与光晕参数
  final CompactTimerPalette palette;

  /// 自定义文本生成器，返回 HH:MM 等字符串
  final String Function(Duration elapsed)? labelBuilder;

  /// 完全自定义内部 Widget，若为空则渲染默认时间文本
  final Widget Function(BuildContext context, Duration elapsed)? innerBuilder;

  static const double _minutesPerCycle = 60;

  @override
  Widget build(BuildContext context) {
    final displayText =
        labelBuilder?.call(elapsed) ?? _defaultLabelText(elapsed);

    return RepaintBoundary(
      child: SleekCircularSlider(
        min: 0,
        max: _minutesPerCycle,
        initialValue: _progressValue(elapsed),
        onChange: null, // 只用于展示，不响应拖动
        appearance: CircularSliderAppearance(
          size: diameter,
          startAngle: 150,
          angleRange: 240,
          animationEnabled: false,
          customWidths: CustomSliderWidths(
            trackWidth: palette.trackWidth,
            progressBarWidth: palette.progressBarWidth,
            handlerSize: 0,
            shadowWidth: palette.shadowWidth,
          ),
          customColors: CustomSliderColors(
            trackColor: palette.trackColor,
            progressBarColors: palette.progressGradient,
            shadowColor: palette.shadowColor,
            shadowMaxOpacity: palette.shadowMaxOpacity,
            dotColor: Colors.transparent,
          ),
          infoProperties: InfoProperties(
            // 使用 innerWidget，自身不显示 info
            modifier: (_) => '',
          ),
        ),
        innerWidget: (value) {
          if (innerBuilder != null) {
            return innerBuilder!(context, elapsed);
          }
          return Center(
            child: Text(
              displayText,
              style: palette.labelStyle.copyWith(
                fontSize: diameter / 3.5,
                color: palette.labelColor ?? palette.progressGradient.last,
              ),
            ),
          );
        },
      ),
    );
  }

  double _progressValue(Duration elapsed) {
    final totalMinutes = elapsed.inMinutes + (elapsed.inSeconds % 60) / 60.0;
    return totalMinutes % _minutesPerCycle;
  }

  String _defaultLabelText(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }
}

/// 渐变与光晕参数配置
class CompactTimerPalette {
  const CompactTimerPalette({
    required this.progressGradient,
    this.trackColor = const Color(0x3DFFFFFF),
    this.shadowColor = const Color(0x80FFFFFF),
    this.shadowMaxOpacity = 0.45,
    this.shadowWidth = 24,
    this.trackWidth = 8,
    this.progressBarWidth = 12,
    this.labelStyle = const TextStyle(
      fontFamily: 'monospace',
      fontWeight: FontWeight.w600,
    ),
    this.labelColor,
  });

  const CompactTimerPalette.normal()
    : this(
        progressGradient: const [
          OceanBreezeColorSchemes.seaSaltBlue,
          OceanBreezeColorSchemes.mintCyan,
          OceanBreezeColorSchemes.clockPrimaryOrange,
        ],
        shadowColor: OceanBreezeColorSchemes.lightSeaSalt,
      );

  factory CompactTimerPalette.paused() {
    return CompactTimerPalette(
      progressGradient: const [
        OceanBreezeColorSchemes.clockPausedLight,
        OceanBreezeColorSchemes.clockPausedLight2,
      ],
      shadowColor: OceanBreezeColorSchemes.clockPausedLight,
    );
  }

  factory CompactTimerPalette.complete() {
    return CompactTimerPalette(
      progressGradient: const [
        OceanBreezeColorSchemes.clockSuccessGreen,
        OceanBreezeColorSchemes.mintCyan,
        OceanBreezeColorSchemes.seaSaltBlue,
      ],
      shadowColor: OceanBreezeColorSchemes.clockSuccessGreen,
    );
  }

  final List<Color> progressGradient;
  final Color trackColor;
  final Color? shadowColor;
  final double shadowMaxOpacity;
  final double shadowWidth;
  final double trackWidth;
  final double progressBarWidth;
  final TextStyle labelStyle;
  final Color? labelColor;
}
