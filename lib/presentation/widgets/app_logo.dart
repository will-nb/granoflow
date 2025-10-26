import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 应用 Logo 组件
/// 支持主题色动态切换和不同尺寸
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 32.0,
    this.showText = true,
    this.variant = AppLogoVariant.primary,
    this.withBackground = false,
  });

  final double size;
  final bool showText;
  final AppLogoVariant variant;
  final bool withBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    Color logoColor;
    Color textColor;
    Color? backgroundColor;
    
    // 统一使用普通版本 SVG，通过 tint 实现前景着色（onPrimary => 纯白）
    const String brandSvgPath = 'assets/logo/granostack-logo.svg';
    
    if (withBackground) {
      // 带背景的 Logo
      if (theme.brightness == Brightness.light) {
        // 浅色主题：深色背景 + 白色前景
        backgroundColor = colorScheme.primary;
        logoColor = Colors.white;
        textColor = Colors.white;
      } else {
        // 深色主题：浅色背景 + 深色前景
        backgroundColor = colorScheme.surface;
        logoColor = colorScheme.onSurface;
        textColor = colorScheme.onSurface;
      }
    } else {
      // 无背景的 Logo
      logoColor = switch (variant) {
        AppLogoVariant.primary => colorScheme.primary,
        AppLogoVariant.secondary => colorScheme.secondary,
        AppLogoVariant.onSurface => colorScheme.onSurface,
        AppLogoVariant.onPrimary => colorScheme.onPrimary,
      };
      textColor = logoColor;
    }

    // 构建 SVG 图标（根据需要着色）
    final String assetPath = brandSvgPath;
    // 当需要前景色（如 withBackground 情况下的白/深色）时使用 tint；
    // onPrimary 使用反色资源本身为白色，可不加色
    final Color? svgTint = withBackground
        ? logoColor
        : switch (variant) {
            AppLogoVariant.onPrimary => Colors.white, // 纯白着色
            AppLogoVariant.onSurface => Theme.of(context).colorScheme.onSurface,
            AppLogoVariant.secondary => Theme.of(context).colorScheme.secondary,
            AppLogoVariant.primary => Theme.of(context).colorScheme.primary,
          };

    final Widget svgIcon = SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: svgTint == null ? null : ColorFilter.mode(svgTint, BlendMode.srcIn),
    );

    Widget logoWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 品牌 SVG 图标
        svgIcon,
        
        if (showText) ...[
          SizedBox(width: size * 0.3),
          // 应用名称
          Text(
            'GranoFlow',
            style: TextStyle(
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );

    if (withBackground && backgroundColor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: logoWidget,
      );
    }

    return logoWidget;
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
