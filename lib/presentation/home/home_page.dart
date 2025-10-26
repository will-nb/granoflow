import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

import '../../core/providers/app_providers.dart';
import '../navigation/navigation_destinations.dart';
import '../timer/timer_page.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(seedInitializerProvider);
    
    final l10n = AppLocalizations.of(context);
    debugPrint('HomePage locale: ${Localizations.localeOf(context)}');
    debugPrint('HomePage greeting: ${l10n.homeGreeting}');

    return GradientPageScaffold(
      appBar: const PageAppBar(
        title: 'Home',
      ),
      drawer: const MainDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final textTheme = Theme.of(context).textTheme;

          final greeting = Text(
            l10n.homeGreeting,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
              color: Colors.white.withValues(alpha: 0.92),
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
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          );
          final double _subtitleH = _measureLineHeight(
            l10n.homeTagline,
            textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          );
          const double _gapH = 8.0; // 与文本之间的实际间距保持一致
          final double _logoTargetH = _greetingH + _gapH + _subtitleH;
          const double _logoBottomTrim = 2.0; // 裁掉 SVG 底部留白（像素）

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
                          child: const AppLogo(
                            size: 200.0,
                            showText: false,
                            variant: AppLogoVariant.onPrimary,
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
                      const SizedBox(height: 24), // 放在按钮上方
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const TimerPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.actionStartTimer),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              ref.read(navigationIndexProvider.notifier).state =
                                  NavigationDestinations.tasks.index;
                            },
                            icon: const Icon(Icons.fact_check_outlined),
                            label: Text(l10n.navPlannedTitle),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              ref.read(navigationIndexProvider.notifier).state =
                                  NavigationDestinations.tasks.index;
                            },
                            icon: const Icon(Icons.inbox_outlined),
                            label: Text(l10n.navInboxTitle),
                          ),
                        ],
                      ),
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
