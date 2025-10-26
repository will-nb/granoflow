import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:granoflow/generated/l10n/app_localizations.dart';
import '../navigation/sidebar_destinations.dart';
import 'app_logo.dart';

/// 主抽屉组件
/// 显示页面导航选项，由主菜单按钮控制
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundImage = isDarkMode
        ? 'assets/images/background.dark.png'
        : 'assets/images/background.light.png';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 美化的 Drawer Header，使用背景图片
          Container(
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(backgroundImage),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // 半透明遮罩，提升文字可读性
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                // 内容区域
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo 和标题
                      Row(
                        children: [
                          const AppLogo(
                            size: 28.0,
                            showText: false,
                            variant: AppLogoVariant.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.homeGreeting,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      Text(
                        l10n.homeTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 导航选项列表
          ...SidebarDestinations.values.map((destination) {
            return ListTile(
              leading: Icon(
                destination.icon,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text(
                destination.label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                // 处理路由跳转
                context.go(destination.route);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
