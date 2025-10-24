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

  static const AppColorTokens light = AppColorTokens(
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF57F17),
    onWarning: Color(0xFF000000),
    info: Color(0xFF1565C0),
    onInfo: Color(0xFFFFFFFF),
    highlight: Color(0xFFF5F5F5),
    onHighlight: Color(0xFF000000),
    disabled: Color(0xFF757575),
    onDisabled: Color(0xFFFFFFFF),
  );

  static const AppColorTokens dark = AppColorTokens(
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF00310A),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF1F1400),
    info: Color(0xFF90A4AE),
    onInfo: Color(0xFFE2E2E6),
    highlight: Color(0xFF3C3830),
    onHighlight: Color(0xFFE2E2E6),
    disabled: Color(0xFF6B6B6B),
    onDisabled: Color(0xFFE2E2E6),
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
