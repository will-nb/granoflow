import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/clock_animation_providers.dart';
import '../../../core/theme/clock_gradients.dart';
import '../../../core/utils/gradient_composer.dart';

/// 背景组件：根据主题模式显示静态海浪背景图片，并叠加动画效果
///
/// 使用预渲染的海浪背景图片作为底层，在图片上方叠加动态的渐变、光晕、纹理和粒子效果。
/// 根据当前主题的亮度（light/dark）自动选择对应的背景图片和动画配置。
class ClockWaveBackground extends ConsumerStatefulWidget {
  const ClockWaveBackground({super.key, required this.state});

  final ClockState state;

  @override
  ConsumerState<ClockWaveBackground> createState() =>
      _ClockWaveBackgroundState();
}

class _ClockWaveBackgroundState
    extends ConsumerState<ClockWaveBackground> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final backgroundImage = isLight
        ? 'assets/images/clock-background-light.png'
        : 'assets/images/clock-background-dark.png';

    final composite = ClockGradients.getWaveGradient(
      brightness: brightness,
      state: widget.state,
    );
    final args = WaveAnimationArgs(brightness: brightness, state: widget.state);
    final controller = ref.watch(waveAnimationControllerProvider(args));

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 底层：静态背景图片
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 上层：动画层（半透明叠加，保持背景图片清晰可见）
          Opacity(
            opacity: 0.7, // 整体透明度，确保背景图片清晰可见
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final values = controller.values;
                return CustomPaint(
                  painter: _WaveAnimationPainter(
                    composite: composite,
                    values: values,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 动画层绘制器：在背景图片上方绘制动态效果
class _WaveAnimationPainter extends CustomPainter {
  _WaveAnimationPainter({required this.composite, required this.values});

  final CompositeWaveGradient composite;
  final WaveAnimationValues values;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    int linearIndex = 0;
    for (final layer in composite.layers) {
      switch (layer.kind) {
        case WaveLayerKind.linear:
          _paintLinearLayer(
            canvas,
            rect,
            layer as WaveLinearGradientLayer,
            linearIndex == 0
                ? values.backgroundOffset
                : values.foregroundOffset,
          );
          linearIndex++;
          break;
        case WaveLayerKind.radial:
          _paintRadialLayer(canvas, rect, layer as WaveRadialGradientLayer);
          break;
        case WaveLayerKind.texture:
          _paintTextureLayer(canvas, rect, layer as WaveTextureLayer);
          break;
        case WaveLayerKind.particle:
          _paintParticleLayer(canvas, rect, layer as WaveParticleLayer);
          break;
      }
    }
  }

  void _paintLinearLayer(
    Canvas canvas,
    Rect rect,
    WaveLinearGradientLayer layer,
    double offset,
  ) {
    final LinearGradient gradient = LinearGradient(
      begin: layer.begin,
      end: layer.end,
      colors: layer.colors,
      stops: layer.stops,
    );

    final Rect shiftedRect = rect.shift(Offset(offset, 0));
    final Paint paint = Paint()
      ..shader = gradient.createShader(shiftedRect)
      ..blendMode = layer.blendMode ?? BlendMode.srcOver;

    canvas.drawRect(rect, paint);
  }

  void _paintRadialLayer(
    Canvas canvas,
    Rect rect,
    WaveRadialGradientLayer layer,
  ) {
    final Alignment alignment = layer.center.resolve(TextDirection.ltr);
    final double offsetX = values.foregroundOffset / rect.width;
    final Alignment shifted = Alignment(
      (alignment.x + offsetX).clamp(-1.5, 1.5),
      alignment.y,
    );

    final List<Color> colors = layer.colors
        .map(
          (color) => color.withValues(
            alpha: (color.a / 255.0 * (0.6 + 0.4 * values.glowIntensity)).clamp(0, 1),
          ),
        )
        .toList(growable: false);

    final RadialGradient gradient = RadialGradient(
      center: shifted,
      radius: layer.radius,
      colors: colors,
      stops: layer.stops,
    );

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..blendMode = layer.blendMode ?? BlendMode.srcOver;

    canvas.drawRect(rect, paint);
  }

  void _paintTextureLayer(Canvas canvas, Rect rect, WaveTextureLayer layer) {
    final double baseHeight = rect.height * 0.6;
    final double amplitude = values.textureAmplitude * layer.scale;
    final double wavelength = rect.width / (3 * layer.scale.clamp(0.6, 2.0));
    final double phaseShift = values.textureShift * 2 * math.pi;

    final Path path = Path()..moveTo(rect.left, rect.bottom);

    for (double x = rect.left; x <= rect.right; x += rect.width / 60) {
      final double wave = math.sin((x / wavelength) * 2 * math.pi + phaseShift);
      final double y = baseHeight + wave * amplitude + layer.offset.dy;
      path.lineTo(x, y);
    }

    path
      ..lineTo(rect.right, rect.bottom)
      ..close();

    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: layer.opacity)
      ..blendMode = layer.blendMode;

    canvas.drawPath(path, paint);
  }

  void _paintParticleLayer(Canvas canvas, Rect rect, WaveParticleLayer layer) {
    final int count = (layer.density * 40).clamp(8, 50).round();
    final Paint paint = Paint()
      ..color = layer.color.withValues(alpha: layer.opacity)
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus;

    for (int i = 0; i < count; i++) {
      final double base = _pseudoRandom(i);
      final double x = ((base + values.particleShift) % 1) * rect.width;
      final double ySeed = _pseudoRandom(i + 31);
      final double y = rect.height * (0.25 + 0.5 * ySeed);
      final double radius = 1.2 + 1.4 * _pseudoRandom(i + 17);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  double _pseudoRandom(int seed) {
    return _fract(math.sin(seed * 12.9898) * 43758.5453);
  }

  double _fract(double value) {
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _WaveAnimationPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.composite != composite;
  }

  @override
  bool shouldRebuildSemantics(covariant _WaveAnimationPainter oldDelegate) =>
      false;
}
