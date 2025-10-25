import 'package:flutter/material.dart';

import '../../core/theme/app_gradients.dart';

/// 可复用的渐变背景组件
/// 支持多种 Ocean Breeze 渐变效果
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.gradientType = GradientType.primary,
    this.customGradient,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
  });

  /// 背景上的子组件
  final Widget child;

  /// 渐变类型
  final GradientType gradientType;

  /// 自定义渐变（优先级高于 gradientType）
  final Gradient? customGradient;

  /// 渐变透明度
  final double opacity;

  /// 混合模式
  final BlendMode blendMode;

  @override
  Widget build(BuildContext context) {
    final gradient = customGradient ?? AppGradients.getGradient(gradientType);
    
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Opacity(
        opacity: opacity,
        child: GradientBlendMode(
          blendMode: blendMode,
          child: child,
        ),
      ),
    );
  }
}

/// 渐变卡片组件
/// 带有渐变背景的卡片容器
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.gradientType = GradientType.secondary,
    this.customGradient,
    this.margin,
    this.padding,
    this.borderRadius,
    this.elevation = 2.0,
    this.shadowColor,
  });

  /// 卡片内容
  final Widget child;

  /// 渐变类型
  final GradientType gradientType;

  /// 自定义渐变
  final Gradient? customGradient;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 阴影高度
  final double elevation;

  /// 阴影颜色
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final gradient = customGradient ?? AppGradients.getGradient(gradientType);
    final theme = Theme.of(context);
    
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

/// 渐变按钮组件
/// 带有渐变背景的按钮
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradientType = GradientType.primary,
    this.customGradient,
    this.padding,
    this.borderRadius,
    this.elevation = 0.0,
    this.disabled = false,
  });

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮内容
  final Widget child;

  /// 渐变类型
  final GradientType gradientType;

  /// 自定义渐变
  final Gradient? customGradient;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 阴影高度
  final double elevation;

  /// 是否禁用
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final gradient = customGradient ?? AppGradients.getGradient(gradientType);
    final isEnabled = onPressed != null && !disabled;
    
    return Material(
      elevation: isEnabled ? elevation : 0.0,
      borderRadius: borderRadius ?? BorderRadius.circular(8.0),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: isEnabled ? gradient : null,
            color: isEnabled ? null : Colors.grey.withValues(alpha: 0.3),
            borderRadius: borderRadius ?? BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 渐变页面背景
/// 为整个页面提供渐变背景
class GradientPageBackground extends StatelessWidget {
  const GradientPageBackground({
    super.key,
    required this.child,
    this.gradientType = GradientType.primary,
    this.customGradient,
    this.safeArea = true,
  });

  /// 页面内容
  final Widget child;

  /// 渐变类型
  final GradientType gradientType;

  /// 自定义渐变
  final Gradient? customGradient;

  /// 是否使用安全区域
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final gradient = customGradient ?? AppGradients.getGradient(gradientType);
    
    Widget content = Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: child,
    );

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return content;
  }
}

/// 混合模式组件
/// 用于控制渐变的混合效果
class GradientBlendMode extends StatelessWidget {
  const GradientBlendMode({
    super.key,
    required this.child,
    required this.blendMode,
  });

  final Widget child;
  final BlendMode blendMode;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: GradientBlendModePainter(blendMode: blendMode),
      child: child,
    );
  }
}

/// 混合模式绘制器
class GradientBlendModePainter extends CustomPainter {
  const GradientBlendModePainter({
    required this.blendMode,
  });

  final BlendMode blendMode;

  @override
  void paint(Canvas canvas, Size size) {
    // 这里可以实现自定义的混合模式效果
    // 目前使用默认的混合模式
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
