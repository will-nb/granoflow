import 'package:flutter/material.dart';

/// InputDecoration 构建器工具类
/// 
/// 提供通用的 InputDecoration 构建器，用于统一输入框样式
/// 可在多个地方复用，保持输入框样式的一致性
class InputDecorationBuilder {
  const InputDecorationBuilder._();

  /// 构建 UnderlineInputBorder 样式的 InputDecoration
  /// 
  /// [context] - BuildContext（用于获取主题）
  /// [hintText] - 占位符文本（可选）
  /// [isFocused] - 是否处于焦点状态（用于确定边框颜色和宽度）
  /// 
  /// 返回：InputDecoration
  /// 
  /// 样式规范：
  /// - border: UnderlineInputBorder
  /// - 边框颜色：normal 状态使用 outline.withValues(alpha: 0.3)，focused 状态使用 primary
  /// - 边框宽度：normal 状态 1dp，focused 状态 1.5dp
  /// - 占位符颜色：onSurfaceVariant.withValues(alpha: 0.6)
  static InputDecoration buildUnderlineInputDecoration(
    BuildContext context, {
    String? hintText,
    bool isFocused = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 根据焦点状态确定边框颜色和宽度
    final borderColor = isFocused
        ? colorScheme.primary
        : colorScheme.outline.withValues(alpha: 0.3);
    final borderWidth = isFocused ? 1.5 : 1.0;

    return InputDecoration(
      hintText: hintText,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      border: UnderlineInputBorder(
        borderSide: BorderSide(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      isDense: true,
    );
  }
}

