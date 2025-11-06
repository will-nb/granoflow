import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/pomodoro_animation_providers.dart';
import '../../../core/theme/pomodoro_gradients.dart';
import '../../../core/utils/gradient_composer.dart';

/// 背景组件：根据主题与计时状态渲染海浪渐变与动效
class PomodoroWaveBackground extends ConsumerStatefulWidget {
  const PomodoroWaveBackground({super.key, required this.state});

  final PomodoroState state;

  @override
  ConsumerState<PomodoroWaveBackground> createState() =>
      _PomodoroWaveBackgroundState();
}

class _PomodoroWaveBackgroundState
    extends ConsumerState<PomodoroWaveBackground> {
  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final composite = PomodoroGradients.getWaveGradient(
      brightness: brightness,
      state: widget.state,
    );
    final args = WaveAnimationArgs(brightness: brightness, state: widget.state);
    final controller = ref.watch(waveAnimationControllerProvider(args));

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final values = controller.values;
          return CustomPaint(
            painter: _WaveBackgroundPainter(
              composite: composite,
              values: values,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WaveBackgroundPainter extends CustomPainter {
  _WaveBackgroundPainter({required this.composite, required this.values});

  final CompositeWaveGradient composite;
  final WaveAnimationValues values;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    _paintFallback(canvas, rect);

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

  void _paintFallback(Canvas canvas, Rect rect) {
    final Paint paint = Paint()..shader = composite.fallback.createShader(rect);
    canvas.drawRect(rect, paint);
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
  bool shouldRepaint(covariant _WaveBackgroundPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.composite != composite;
  }

  @override
  bool shouldRebuildSemantics(covariant _WaveBackgroundPainter oldDelegate) =>
      false;
}
