import 'package:flutter/material.dart';

/// Additional semantic colors that do not exist on [ColorScheme].
@immutable
class AppColorTokens extends ThemeExtension<AppColorTokens> {
  const AppColorTokens({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;

  static const AppColorTokens light = AppColorTokens(
    success: Color(0xFF2E7D32),
    onSuccess: Color(0xFFFFFFFF),
    warning: Color(0xFFF57F17),
    onWarning: Color(0xFF000000),
  );

  static const AppColorTokens dark = AppColorTokens(
    success: Color(0xFF81C784),
    onSuccess: Color(0xFF00310A),
    warning: Color(0xFFFFB74D),
    onWarning: Color(0xFF1F1400),
  );

  @override
  AppColorTokens copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
  }) {
    return AppColorTokens(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
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
