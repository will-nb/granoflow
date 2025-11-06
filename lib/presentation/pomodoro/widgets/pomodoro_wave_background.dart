import 'package:flutter/material.dart';

import '../../../core/theme/pomodoro_gradients.dart';

/// 背景组件：根据主题模式显示静态海浪背景图片
///
/// 使用预渲染的海浪背景图片替代动态绘制，提供更好的性能和视觉效果。
/// 根据当前主题的亮度（light/dark）自动选择对应的背景图片。
class PomodoroWaveBackground extends StatelessWidget {
  const PomodoroWaveBackground({super.key, required this.state});

  final PomodoroState state;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final backgroundImage = isLight
        ? 'assets/images/clock-background-light.png'
        : 'assets/images/clock-background-dark.png';

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
