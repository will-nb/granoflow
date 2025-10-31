import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'drawer/drawer_header.dart' as drawer;
import 'drawer/drawer_navigation_list.dart';
import 'drawer/drawer_projects_section.dart';
import 'drawer/drawer_tags_section.dart';

/// 主抽屉组件
/// 显示页面导航选项和标签分组，由主菜单按钮控制
class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          // 抽屉头部
          const drawer.DrawerHeader(),
          // 可滚动的内容区域
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 导航选项列表
                const DrawerNavigationList(),
                
                // 项目预览区域
                const Divider(height: 1),
                const DrawerProjectsSection(),
                
                // 标签分组展示
                const Divider(height: 1),
                const DrawerTagsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}