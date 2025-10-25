import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/sidebar_destinations.dart';

/// 主抽屉组件
/// 显示页面导航选项，由主菜单按钮控制
class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'GranoFlow',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
