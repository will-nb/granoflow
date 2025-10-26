import 'package:flutter/material.dart';

/// 应用 Logo 组件
/// 支持主题色动态切换和不同尺寸
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.variant = AppLogoVariant.primary,
  });

  final double size;
  final bool showText;
  final AppLogoVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 根据变体选择颜色
    final logoColor = switch (variant) {
      AppLogoVariant.primary => colorScheme.primary,
      AppLogoVariant.secondary => colorScheme.secondary,
      AppLogoVariant.onSurface => colorScheme.onSurface,
      AppLogoVariant.onPrimary => colorScheme.onPrimary,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo 图标
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: logoColor,
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: logoColor.withValues(alpha: 0.3),
                blurRadius: size * 0.1,
                offset: Offset(0, size * 0.05),
              ),
            ],
          ),
          child: Icon(
            Icons.water_drop_outlined,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
        
        if (showText) ...[
          SizedBox(width: size * 0.3),
          // 应用名称
          Text(
            'GranoFlow',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              color: logoColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

/// Logo 变体枚举
enum AppLogoVariant {
  /// 主色调
  primary,
  /// 辅色调
  secondary,
  /// 表面文字色
  onSurface,
  /// 主色上的文字色
  onPrimary,
}

/// 简化的 Logo 图标组件（仅图标）
class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({
    super.key,
    this.size = 32.0,
    this.variant = AppLogoVariant.primary,
  });

  final double size;
  final AppLogoVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final logoColor = switch (variant) {
      AppLogoVariant.primary => colorScheme.primary,
      AppLogoVariant.secondary => colorScheme.secondary,
      AppLogoVariant.onSurface => colorScheme.onSurface,
      AppLogoVariant.onPrimary => colorScheme.onPrimary,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: logoColor,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: logoColor.withValues(alpha: 0.3),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Icon(
        Icons.water_drop_outlined,
        color: Colors.white,
        size: size * 0.6,
      ),
    );
  }
}
