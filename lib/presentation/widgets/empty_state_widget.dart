import 'package:flutter/material.dart';

/// 通用的空状态组件
/// 
/// 支持图标、文本和自定义样式，可在多个地方复用
/// 用于显示列表为空时的友好提示
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.iconSize = 64.0,
    this.padding,
    this.iconColor,
    this.textStyle,
  });

  /// 提示文本（必需）
  final String message;

  /// 图标（可选，默认 Icons.inbox_outlined）
  final IconData? icon;

  /// 图标尺寸（默认 64dp）
  final double iconSize;

  /// 内边距（可选，默认 EdgeInsets.symmetric(horizontal: 32, vertical: 64)）
  final EdgeInsetsGeometry? padding;

  /// 图标颜色（可选，使用主题颜色）
  final Color? iconColor;

  /// 文本样式（可选，使用主题文本样式）
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 使用传入的颜色或主题颜色
    final effectiveIconColor = iconColor ?? 
        colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    final effectiveTextStyle = textStyle ?? 
        theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        );
    final effectivePadding = padding ?? 
        const EdgeInsets.symmetric(horizontal: 32, vertical: 64);

    return Center(
      child: Padding(
        padding: effectivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
              const SizedBox(height: 16),
            ],
            // 提示文字
            Text(
              message,
              style: effectiveTextStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

