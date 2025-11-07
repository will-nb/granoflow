import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 粒子类
class Particle {
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.lifetime,
  });

  /// 位置
  Offset position;

  /// 速度
  Offset velocity;

  /// 大小
  double size;

  /// 颜色
  Color color;

  /// 生命周期（0.0 到 1.0）
  double lifetime;

  /// 更新粒子状态
  void update(double deltaTime) {
    // 更新位置
    position += velocity * deltaTime;

    // 更新生命周期
    lifetime = (lifetime + deltaTime * 2.0).clamp(0.0, 1.0);
  }

  /// 是否已死亡
  bool get isDead => lifetime >= 1.0;
}

/// 爆炸粒子效果绘制器
class ExplosionParticlePainter extends CustomPainter {
  ExplosionParticlePainter({
    required this.particles,
    required this.animation,
  }) : super(repaint: animation);

  /// 粒子列表
  final List<Particle> particles;

  /// 动画值（0.0 到 1.0）
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final deltaTime = 0.016; // 假设 60fps

    for (final particle in particles) {
      if (particle.isDead) {
        continue;
      }

      // 更新粒子
      particle.update(deltaTime);

      // 计算透明度（从1.0到0.0）
      final opacity = 1.0 - particle.lifetime;

      // 计算大小（从原始大小到0）
      final currentSize = particle.size * (1.0 - particle.lifetime);

      // 绘制粒子
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        particle.position,
        currentSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ExplosionParticlePainter oldDelegate) {
    return particles != oldDelegate.particles ||
        animation.value != oldDelegate.animation.value;
  }
}

/// 粒子生成器
class ParticleGenerator {
  /// 从标签中心生成粒子
  static List<Particle> generateParticles({
    required Offset center,
    required Color backgroundColor,
    required Color textColor,
    required Color primaryColor,
    required int count,
    required Size labelSize,
  }) {
    final random = math.Random();
    final particles = <Particle>[];

    // 颜色列表
    final colors = [backgroundColor, textColor, primaryColor];

    for (int i = 0; i < count; i++) {
      // 随机角度（0 到 360 度）
      final angle = random.nextDouble() * 2 * math.pi;

      // 随机速度（100 到 300 dp/s）
      final speed = 100 + random.nextDouble() * 200;

      // 计算速度向量
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );

      // 随机大小（2 到 6 dp）
      final size = 2 + random.nextDouble() * 4;

      // 随机颜色
      final color = colors[random.nextInt(colors.length)];

      particles.add(Particle(
        position: center,
        velocity: velocity,
        size: size,
        color: color,
        lifetime: 0.0,
      ));
    }

    return particles;
  }
}

