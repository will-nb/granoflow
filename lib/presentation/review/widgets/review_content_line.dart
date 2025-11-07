import 'package:flutter/material.dart';

/// 回顾内容行组件（基础组件）
/// 支持淡入动画，无滑动效果
class ReviewContentLine extends StatelessWidget {
  const ReviewContentLine({
    super.key,
    required this.text,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.topSpacing = 16,
    this.bottomSpacing = 16,
    this.textAlign = TextAlign.start,
    this.visible = true,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  /// 显示的文本
  final String text;

  /// 字体大小
  final double fontSize;

  /// 字重
  final FontWeight fontWeight;

  /// 文字颜色（如果为 null，使用主题颜色）
  final Color? color;

  /// 顶部间距
  final double topSpacing;

  /// 底部间距
  final double bottomSpacing;

  /// 文本对齐方式
  final TextAlign textAlign;

  /// 是否可见（用于控制淡入动画）
  final bool visible;

  /// 动画时长
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = color ?? theme.colorScheme.onSurface;

    return AnimatedOpacity(
      duration: animationDuration,
      opacity: visible ? 1.0 : 0.0,
      curve: Curves.easeOut,
      child: Padding(
        padding: EdgeInsets.only(
          top: topSpacing,
          bottom: bottomSpacing,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
            height: 1.5,
          ),
          textAlign: textAlign,
        ),
      ),
    );
  }
}

