import 'package:flutter/material.dart';

/// Additional semantic colors that do not exist on [ColorScheme].
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.highlight,
    required this.onHighlight,
    required this.disabled,
    required this.onDisabled,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color info;
  final Color onInfo;
  final Color highlight;
  final Color onHighlight;
  final Color disabled;
  final Color onDisabled;

  /// Ocean Breeze 浅色主题颜色令牌
  static const AppColorTokens light = AppColorTokens(
    success: Color(0xFF7ED2A8), // 柔和薄荷绿
    onSuccess: Color(0xFF1E4D67), // 海军蓝
    warning: Color(0xFFFFD48A), // 柔暖黄
    onWarning: Color(0xFF1E4D67), // 海军蓝
    info: Color(0xFF81C8DD), // 较浅蓝灰
    onInfo: Color(0xFF1E4D67), // 海军蓝
    highlight: Color(0xFFF5FAFC), // 天际白
    onHighlight: Color(0xFF1E4D67), // 海军蓝
    disabled: Color(0xFFA5B7C0), // 禁用文字
    onDisabled: Color(0xFF4C6F80), // 次文字
  );

  /// Ocean Breeze Dark - 深海流光功能色令牌
  static const AppColorTokens dark = AppColorTokens(
    success: Color(0xFF7ED2A8),
    onSuccess: Color(0xFF1E4D67),
    warning: Color(0xFFFFD48A),
    onWarning: Color(0xFF1E4D67),
    info: Color(0xFF81C8DD),
    onInfo: Color(0xFF1E4D67),
    highlight: Color(0xFF4C6F80),
    onHighlight: Color(0xFFF5FAFC),
    disabled: Color(0xFFA5B7C0),
    onDisabled: Color(0xFF4C6F80),
  );

  @override
  AppColorTokens copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? highlight,
    Color? onHighlight,
    Color? disabled,
    Color? onDisabled,
  }) {
    return AppColorTokens(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      highlight: highlight ?? this.highlight,
      onHighlight: onHighlight ?? this.onHighlight,
      disabled: disabled ?? this.disabled,
      onDisabled: onDisabled ?? this.onDisabled,
    );
  }

  @override
  AppColorTokens lerp(ThemeExtension<AppColorTokens>? other, double t) {
    if (other is! AppColorTokens) {
      return this;
    }
    return AppColorTokens(
      success: Color.lerp(success, other.success, t) ?? success,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      onWarning: Color.lerp(onWarning, other.onWarning, t) ?? onWarning,
      info: Color.lerp(info, other.info, t) ?? info,
      onInfo: Color.lerp(onInfo, other.onInfo, t) ?? onInfo,
      highlight: Color.lerp(highlight, other.highlight, t) ?? highlight,
      onHighlight: Color.lerp(onHighlight, other.onHighlight, t) ?? onHighlight,
      disabled: Color.lerp(disabled, other.disabled, t) ?? disabled,
      onDisabled: Color.lerp(onDisabled, other.onDisabled, t) ?? onDisabled,
    );
  }
}

extension AppThemeColors on BuildContext {
  AppColorTokens get colorTokens {
    final tokens = Theme.of(this).extension<AppColorTokens>();
    if (tokens == null) {
      throw StateError('AppColorTokens not found on Theme');
    }
    return tokens;
  }
}
