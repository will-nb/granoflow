import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:granoflow/generated/l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/home_statistics_providers.dart';
import '../widgets/page_app_bar.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_drawer.dart';
import '../widgets/gradient_page_scaffold.dart';
import 'widgets/home_statistics_widget.dart';
import 'widgets/task_search_bar.dart';

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
            textAlign: TextAlign.start, // 文本左对齐，与 Column 对齐方式一致
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
            textAlign: TextAlign.start, // 文本左对齐，与 Column 对齐方式一致
          );

          // 根据主题亮度选择 Logo variant (Choose Logo variant based on theme brightness)
          final logoVariant = theme.brightness == Brightness.light
              ? AppLogoVariant.primary      // Light 模式：彩色 Logo
              : AppLogoVariant.onPrimary;   // Dark 模式：白色 Logo

          // 将 Logo + 标题 + 标语打包为一个横向 heroBlock
          final heroBlock = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, // 垂直居中对齐
            children: [
              // 左侧 Logo：使用固定尺寸，简化布局
              SizedBox(
                width: isWide ? 80 : 64,
                height: isWide ? 80 : 64,
                child: AppLogo(
                  size: isWide ? 80 : 64,
                  showText: false,
                  variant: logoVariant,
                ),
              ),
              SizedBox(width: isWide ? 20 : 16), // 增加间距，更统一
              // 文本区域：移除 Transform，使用标准布局
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start, // 文本左对齐
                  children: [
                    greeting,
                    const SizedBox(height: 8),
                    subtitle,
                  ],
                ),
              ),
            ],
          );

          // 响应式布局
          if (isWide) {
            // 横屏：两栏布局
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth >= 1200 ? 48 : 32,
                vertical: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧栏：Hero + 搜索栏
                  Flexible(
                    flex: constraints.maxWidth >= 1200 ? 35 : 30,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        heroBlock,
                        const SizedBox(height: 24),
                        TaskSearchBar(
                          onTap: () => context.go('/search'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: constraints.maxWidth >= 1200 ? 48 : 32,
                  ),
                  // 右侧栏：统计表
                  Flexible(
                    flex: constraints.maxWidth >= 1200 ? 50 : 40,
                    child: const HomeStatisticsWidget(),
                  ),
                ],
              ),
            );
          } else {
            // 竖屏：垂直布局
            return RefreshIndicator(
              onRefresh: () async {
                // 刷新所有统计数据
                ref.invalidate(todayStatisticsProvider);
                ref.invalidate(thisWeekStatisticsProvider);
                ref.invalidate(thisMonthStatisticsProvider);
                ref.invalidate(totalStatisticsProvider);
                ref.invalidate(topCompletedDateProvider);
                ref.invalidate(topFocusDateProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    heroBlock,
                    const SizedBox(height: 24),
                    TaskSearchBar(
                      onTap: () => context.go('/search'),
                    ),
                    const HomeStatisticsWidget(),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
