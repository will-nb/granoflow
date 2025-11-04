import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/sidebar_destinations.dart';

/// 抽屉导航列表组件
/// 显示导航选项列表（收集箱、任务清单等），处理路由跳转
class DrawerNavigationList extends StatelessWidget {
  const DrawerNavigationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: SidebarDestinations.values.map((destination) {
        return ListTile(
          leading: Icon(
            destination.icon,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          title: Text(
            destination.label(context),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }
}
