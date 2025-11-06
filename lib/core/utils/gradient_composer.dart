import 'package:flutter/material.dart';

/// 海浪主题的复合渐变层类型
enum WaveLayerKind { linear, radial, texture, particle }

/// 抽象的海浪渐变层描述
abstract class WaveLayer {
  const WaveLayer();

  WaveLayerKind get kind;
}

/// 线性渐变层配置
class WaveLinearGradientLayer extends WaveLayer {
  const WaveLinearGradientLayer({
    required this.begin,
    required this.end,
    required this.colors,
    this.stops,
    this.blendMode,
  });

  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<Color> colors;
  final List<double>? stops;
  final BlendMode? blendMode;

  @override
  WaveLayerKind get kind => WaveLayerKind.linear;
}

/// 径向渐变层配置
class WaveRadialGradientLayer extends WaveLayer {
  const WaveRadialGradientLayer({
    required this.center,
    required this.radius,
    required this.colors,
    this.stops,
    this.blendMode,
  });

  final AlignmentGeometry center;
  final double radius;
  final List<Color> colors;
  final List<double>? stops;
  final BlendMode? blendMode;

  @override
  WaveLayerKind get kind => WaveLayerKind.radial;
}

/// 纹理叠加层配置（例如泡沫、浪花）
class WaveTextureLayer extends WaveLayer {
  const WaveTextureLayer({
    required this.asset,
    this.opacity = 1.0,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.blendMode = BlendMode.srcOver,
  });

  final String asset;
  final double opacity;
  final double scale;
  final Offset offset;
  final BlendMode blendMode;

  @override
  WaveLayerKind get kind => WaveLayerKind.texture;
}

/// 粒子样式类型（星点、泡泡等）
enum WaveParticleStyle { starGlint, bubble }

/// 粒子叠加层配置
class WaveParticleLayer extends WaveLayer {
  const WaveParticleLayer({
    required this.style,
    required this.color,
    this.density = 0.5,
    this.opacity = 1.0,
  });

  final WaveParticleStyle style;
  final Color color;

  /// 粒子密度，0-1 范围，数值越大粒子越多
  final double density;
  final double opacity;

  @override
  WaveLayerKind get kind => WaveLayerKind.particle;
}

/// 复合海浪渐变配置，包含一个兜底 LinearGradient 和若干附加层
class CompositeWaveGradient {
  const CompositeWaveGradient({
    required this.fallback,
    this.layers = const <WaveLayer>[],
  });

  /// 在不支持自定义叠加时使用的线性渐变
  final LinearGradient fallback;

  /// 额外的叠加层列表（线性、径向、纹理、粒子）
  final List<WaveLayer> layers;

  bool get hasLayers => layers.isNotEmpty;

  /// 筛选出指定类型的层
  List<T> layersOf<T extends WaveLayer>() {
    return layers.whereType<T>().toList(growable: false);
  }
}

/// 工具类：提供简单的合成辅助方法
class GradientComposer {
  const GradientComposer._();

  /// 构建仅包含单一线性渐变的 CompositeWaveGradient
  static CompositeWaveGradient singleLinear(LinearGradient gradient) {
    return CompositeWaveGradient(fallback: gradient);
  }
}
