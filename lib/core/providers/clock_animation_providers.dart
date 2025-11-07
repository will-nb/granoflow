import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/clock_gradients.dart';

/// 波浪动画配置参数
@immutable
class WaveAnimationConfig {
  const WaveAnimationConfig({
    required this.foregroundSpeed,
    required this.backgroundSpeed,
    required this.textureSpeed,
    required this.particleSpeed,
    required this.glowCycleSeconds,
    required this.foregroundAmplitude,
    required this.backgroundAmplitude,
    required this.textureAmplitude,
  });

  final double foregroundSpeed;
  final double backgroundSpeed;
  final double textureSpeed;
  final double particleSpeed;
  final double glowCycleSeconds;
  final double foregroundAmplitude;
  final double backgroundAmplitude;
  final double textureAmplitude;

  WaveAnimationConfig copyWith({
    double? foregroundSpeed,
    double? backgroundSpeed,
    double? textureSpeed,
    double? particleSpeed,
    double? glowCycleSeconds,
    double? foregroundAmplitude,
    double? backgroundAmplitude,
    double? textureAmplitude,
  }) {
    return WaveAnimationConfig(
      foregroundSpeed: foregroundSpeed ?? this.foregroundSpeed,
      backgroundSpeed: backgroundSpeed ?? this.backgroundSpeed,
      textureSpeed: textureSpeed ?? this.textureSpeed,
      particleSpeed: particleSpeed ?? this.particleSpeed,
      glowCycleSeconds: glowCycleSeconds ?? this.glowCycleSeconds,
      foregroundAmplitude: foregroundAmplitude ?? this.foregroundAmplitude,
      backgroundAmplitude: backgroundAmplitude ?? this.backgroundAmplitude,
      textureAmplitude: textureAmplitude ?? this.textureAmplitude,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaveAnimationConfig &&
        other.foregroundSpeed == foregroundSpeed &&
        other.backgroundSpeed == backgroundSpeed &&
        other.textureSpeed == textureSpeed &&
        other.particleSpeed == particleSpeed &&
        other.glowCycleSeconds == glowCycleSeconds &&
        other.foregroundAmplitude == foregroundAmplitude &&
        other.backgroundAmplitude == backgroundAmplitude &&
        other.textureAmplitude == textureAmplitude;
  }

  @override
  int get hashCode => Object.hash(
    foregroundSpeed,
    backgroundSpeed,
    textureSpeed,
    particleSpeed,
    glowCycleSeconds,
    foregroundAmplitude,
    backgroundAmplitude,
    textureAmplitude,
  );
}

/// 计算动画配置所需的输入参数
@immutable
class WaveAnimationArgs {
  const WaveAnimationArgs({required this.brightness, required this.state});

  final Brightness brightness;
  final ClockState state;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WaveAnimationArgs &&
        other.brightness == brightness &&
        other.state == state;
  }

  @override
  int get hashCode => Object.hash(brightness, state);
}

/// 动画值输出，用于 CustomPainter 渲染
@immutable
class WaveAnimationValues {
  const WaveAnimationValues({
    required this.elapsed,
    required this.foregroundOffset,
    required this.backgroundOffset,
    required this.textureShift,
    required this.textureAmplitude,
    required this.glowIntensity,
    required this.particleShift,
  });

  final double elapsed;
  final double foregroundOffset;
  final double backgroundOffset;
  final double textureShift;
  final double textureAmplitude;
  final double glowIntensity;
  final double particleShift;
}

WaveAnimationConfig _resolveConfig(WaveAnimationArgs args) {
  final bool isLight = args.brightness == Brightness.light;
  switch (args.state) {
    case ClockState.normal:
      return WaveAnimationConfig(
        foregroundSpeed: isLight ? 0.18 : 0.14,
        backgroundSpeed: isLight ? 0.12 : 0.1,
        textureSpeed: isLight ? 0.08 : 0.06,
        particleSpeed: isLight ? 0.04 : 0.05,
        glowCycleSeconds: isLight ? 6.0 : 7.5,
        foregroundAmplitude: isLight ? 14 : 12,
        backgroundAmplitude: isLight ? 10 : 12,
        textureAmplitude: isLight ? 6 : 5,
      );
    case ClockState.complete:
      return WaveAnimationConfig(
        foregroundSpeed: 0.1,
        backgroundSpeed: 0.08,
        textureSpeed: 0.05,
        particleSpeed: 0.03,
        glowCycleSeconds: 5.0,
        foregroundAmplitude: 10,
        backgroundAmplitude: 8,
        textureAmplitude: 4,
      );
    case ClockState.paused:
      return WaveAnimationConfig(
        foregroundSpeed: 0.04,
        backgroundSpeed: 0.035,
        textureSpeed: 0.02,
        particleSpeed: 0.02,
        glowCycleSeconds: 8.0,
        foregroundAmplitude: 4,
        backgroundAmplitude: 3,
        textureAmplitude: 2,
      );
  }
}

final waveAnimationConfigProvider = Provider.autoDispose
    .family<WaveAnimationConfig, WaveAnimationArgs>(
      (ref, args) => _resolveConfig(args),
    );

/// 管理波浪动画的控制器（内部使用 Ticker），输出抽象的动画值
class WaveAnimationController extends ChangeNotifier implements TickerProvider {
  WaveAnimationController({required WaveAnimationConfig config})
    : _config = config {
    _ticker = createTicker(_handleTick)..start();
  }

  late final Ticker _ticker;
  WaveAnimationConfig _config;
  double _elapsedSeconds = 0.0;

  WaveAnimationConfig get config => _config;

  void updateConfig(WaveAnimationConfig config) {
    if (_config == config) {
      return;
    }
    _config = config;
  }

  WaveAnimationValues get values {
    final double elapsed = _elapsedSeconds;
    final double foregroundOffset =
        math.sin(elapsed * _config.foregroundSpeed * 2 * math.pi) *
        _config.foregroundAmplitude;
    final double backgroundOffset =
        math.sin(elapsed * _config.backgroundSpeed * 2 * math.pi) *
        _config.backgroundAmplitude;
    final double textureShift = (elapsed * _config.textureSpeed) % 1.0;
    final double glowIntensity =
        0.5 +
        0.5 * math.sin((elapsed / _config.glowCycleSeconds) * 2 * math.pi);
    final double particleShift = (elapsed * _config.particleSpeed) % 1.0;

    return WaveAnimationValues(
      elapsed: elapsed,
      foregroundOffset: foregroundOffset,
      backgroundOffset: backgroundOffset,
      textureShift: textureShift,
      textureAmplitude: _config.textureAmplitude,
      glowIntensity: glowIntensity,
      particleShift: particleShift,
    );
  }

  void _handleTick(Duration elapsed) {
    _elapsedSeconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    notifyListeners();
  }

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// 提供波浪动画控制器，确保在参数更新时同步调整配置
final waveAnimationControllerProvider = ChangeNotifierProvider.autoDispose
    .family<WaveAnimationController, WaveAnimationArgs>((ref, args) {
      final config = ref.watch(waveAnimationConfigProvider(args));
      final controller = WaveAnimationController(config: config);

      ref.onDispose(controller.dispose);

      ref.listen<WaveAnimationConfig>(waveAnimationConfigProvider(args), (
        previous,
        next,
      ) {
        if (previous != next) {
          controller.updateConfig(next);
        }
      });

      return controller;
    });
