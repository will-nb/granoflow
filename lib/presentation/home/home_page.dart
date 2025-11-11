import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 触发种子导入，但不监听状态变化（避免无限重建）
    debugPrint('🟢 HomePage: build() called, triggering seed import...');
    try {
      ref.read(seedInitializerProvider);
      debugPrint('🟢 HomePage: seedInitializerProvider read successfully');
    } catch (error, stackTrace) {
      debugPrint('🔴 HomePage: ERROR - Failed to read seedInitializerProvider: $error');
      debugPrint('🔴 HomePage: Stack trace: $stackTrace');
    }
    
    final l10n = AppLocalizations.of(context);

    return GradientPageScaffold(
      appBar: PageAppBar(
        title: l10n.homePageTitle,
      ),
      drawer: const MainDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final theme = Theme.of(context);
          final textTheme = theme.textTheme;
          final colorScheme = theme.colorScheme;
          
          // 根据主题亮度选择文字颜色 (Choose text color based on theme brightness)
          final heroTextColor = theme.brightness == Brightness.light
              ? colorScheme.onSurface  // Light 模式：海军蓝
              : Colors.white;           // Dark 模式：白色

          final greeting = Text(
            l10n.homeGreeting,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: heroTextColor,
              letterSpacing: 0.3,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            textAlign: TextAlign.center,
          );

          final subtitle = Text(
            l10n.homeTagline,
            style: textTheme.bodyLarge?.copyWith(
              color: heroTextColor.withValues(alpha: 0.85),
              height: 1.4,
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
            textAlign: TextAlign.center,
          );

          // 计算两行文本高度，便于让左侧 Logo 精准与顶部/底部对齐
          final textDirection = Directionality.of(context);
          double _measureLineHeight(String text, TextStyle? style) {
            final painter = TextPainter(
              text: TextSpan(text: text, style: style),
              maxLines: 1,
              textDirection: textDirection,
            )..layout(maxWidth: double.infinity);
            return painter.height;
          }
          final double _greetingH = _measureLineHeight(
            l10n.homeGreeting,
            textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: heroTextColor,
              letterSpacing: 0.3,
            ),
          );
          final double _subtitleH = _measureLineHeight(
            l10n.homeTagline,
            textTheme.bodyLarge?.copyWith(
              color: heroTextColor.withValues(alpha: 0.85),
              height: 1.4,
            ),
          );
          const double _gapH = 8.0; // 与文本之间的实际间距保持一致
          final double _logoTargetH = _greetingH + _gapH + _subtitleH;
          const double _logoBottomTrim = 2.0; // 裁掉 SVG 底部留白（像素）

          // 根据主题亮度选择 Logo variant (Choose Logo variant based on theme brightness)
          final logoVariant = theme.brightness == Brightness.light
              ? AppLogoVariant.primary      // Light 模式：彩色 Logo
              : AppLogoVariant.onPrimary;   // Dark 模式：白色 Logo

          // 将 Logo + 标题 + 标语打包为一个横向 heroBlock
          final heroBlock = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐，便于下方延伸
            children: [
              // 左侧 Logo：在保持顶部不变的情况下向下延伸 3px，并整体向右 2px
              Transform.translate(
                offset: const Offset(2.0, 0.0),
                child: SizedBox(
                  height: _logoTargetH + 3.0,
                  width: isWide ? 84 : 72,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        top: 0,
                        bottom: _logoBottomTrim,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: AppLogo(
                            size: 200.0,
                            showText: false,
                            variant: logoVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isWide ? 16 : 12),
              // 修复：将 Flexible 放在 Row 的直接子级，而不是 Transform 内部
              Flexible(
                child: Transform.translate(
                  offset: const Offset(-3.0, 0.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      greeting,
                      const SizedBox(height: _gapH),
                      subtitle,
                    ],
                  ),
                ),
              ),
            ],
          );

          return Center(
            child: Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      heroBlock,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
